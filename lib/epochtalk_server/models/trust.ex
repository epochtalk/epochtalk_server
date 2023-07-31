defmodule EpochtalkServer.Models.Trust do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Trust
  alias EpochtalkServer.Models.TrustBoard
  alias EpochtalkServer.Models.TrustMaxDepth
  alias EpochtalkServer.Models.TrustFeedback
  alias EpochtalkServer.Models.User

  @untrusted 1

  @moduledoc """
  `Trust` model, for performing actions relating to `Trust`

  Each `User` has a list of users who they directly `Trust`

  Data structure represents who each `User` trusts directly, the function `trust_by_user_ids`
  ties this together by recursively checking users in that trust list
  """
  # TODO(akinsey): change user_id_trusted to something that doesn't imply the user is trusted
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          user_id_trusted: non_neg_integer | nil,
          type: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:user_id, :user_id_trusted, :type]}
  @primary_key false
  schema "trust" do
    belongs_to :user, User
    belongs_to :trusted_user_id, User, foreign_key: :user_id_trusted
    field :type, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `Trust` model
  """
  @spec changeset(
          trust :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(trust, attrs \\ %{}) do
    trust
    |> cast(attrs, [:user_id, :user_id_trusted, :type])
    |> validate_required([:user_id, :user_id_trusted, :type])
  end

  ## === Database Functions ===

  @doc """
  Query all `Trust` models
  """
  @spec trust_by_user_ids(trusted :: [non_neg_integer]) :: [Ecto.Changeset.t()]
  def trust_by_user_ids(trusted) do
    query =
      from t in Trust,
        where: t.user_id in ^trusted

    Repo.all(query)
  end

  ## === Public Helper Functions ===

  @doc """
  Appends `Trust` statistics to each `Post` in list if provided with a valid authenticated `User`
  """
  @spec maybe_append_trust_stats_to_posts(
          posts :: [],
          authed_user :: User.t() | nil
        ) :: [Post.t()]
  def maybe_append_trust_stats_to_posts(posts, authed_user)
  def maybe_append_trust_stats_to_posts(posts, nil), do: posts

  def maybe_append_trust_stats_to_posts(posts, authed_user) do
    authed_user_id = authed_user.id
    # pre calculate trust network for authed user to be optimal
    max_depth = TrustMaxDepth.by_user_id(authed_user_id)
    trusted = Trust.sources_by_user_id(authed_user_id, max_depth)
    # append trust statistics for each post's authoring user
    posts
    |> Enum.map(fn post ->
      user_trust_stats =
        TrustFeedback.statistics_by_user_id(post.user_id, authed_user_id, trusted)

      post |> Map.put(:user_trust_stats, user_trust_stats)
    end)
  end

  @doc """
  Appends `trust_visible` field to `Thread` if provided with a valid authenticated `User`
  """
  @spec maybe_append_trust_visible_to_thread(
          thread :: Thread.t(),
          authed_user :: User.t() | nil
        ) :: Thread.t()
  def maybe_append_trust_visible_to_thread(thread, authed_user)
  def maybe_append_trust_visible_to_thread(thread, nil), do: thread

  def maybe_append_trust_visible_to_thread(thread, _authed_user) do
    trust_boards = TrustBoard.all()
    trust_visible = Enum.filter(trust_boards, &(&1.board_id == thread.board_id)) != []
    thread |> Map.put(:trust_visible, trust_visible)
  end

  @doc """
  Determines the set of users in a user's `Trust` network, `max_depth` is configured by the user.

  Algorithm Description:
  * Starts with current users trust list, or DefaultTrustList's if user does not have one
  * Iterates recursively through trust list up to `max_depth`, updates their scores based on whether they are trusted or not
  * Returns all users who have a positive score (trusted sources)
  """
  @spec sources_by_user_id(
          user_id :: non_neg_integer,
          max_depth :: non_neg_integer,
          debug :: [] | nil
        ) :: [non_neg_integer]
  def sources_by_user_id(user_id, max_depth, debug \\ nil) do
    depth = 0..(max_depth - 1) |> Enum.to_list()

    %{sources: sources, debug: debug} =
      Enum.reduce(depth, %{sources: [], untrusted: %{}, last: [user_id], debug: debug}, fn i,
                                                                                           acc ->
        debug = if acc.debug, do: Map.put(acc.debug, i, [])

        if acc.last == [] do
          # do nothing
          acc
        else
          # get trust list for list of trusted users. Initially just the truster, in subsequent
          # runs this will be a calculated list of the previous iterations trusted users
          current_trust_list_data = Trust.trust_by_user_ids(acc.last)

          # the votes list, at the end of all iterations determines if a
          # user is trusted or not based on the number of votes
          votes = update_votes(current_trust_list_data)

          # using current trust list data (queried using last), update source, untrusted, last and debug
          %{sources: sources, untrusted: untrusted, last: last, debug: debug} =
            update_sources_untrusted_last_and_debug(acc, votes, current_trust_list_data, i, debug)

          # if user has no initial trust list, use default trust list
          %{sources: sources, last: last, debug: debug} =
            maybe_use_default_trust_list(sources, last, votes, debug, i)

          %{
            sources: sources,
            untrusted: untrusted,
            last: last,
            debug: debug
          }
        end
      end)

    # returns unique user ids after adding truster user id to sources, every user trusts themselves
    sources = Enum.uniq(sources ++ [user_id]) |> Enum.filter(& &1)

    if debug, do: Map.put(debug, 0, Enum.at(debug, 0) ++ [[user_id, 0]]) |> Logger.debug()

    sources
  end

  ## === Private Helper Functions ===

  # takes in trusted user's list (last) which is calculated in previous iteration of outer loop
  # updates truster list votes list
  defp update_votes(current_trust_list_data) do
    # iterate through all user's trust data, return votes
    Enum.reduce(current_trust_list_data, %{}, fn trust, votes ->
      current_user_id = trust.user_id_trusted
      votes = votes |> Map.put_new(current_user_id, 0)
      # check if user is trusted or untrusted
      # increment or decrement votes based on trust type
      if trust.type == @untrusted,
        do: votes |> Map.put(current_user_id, votes[current_user_id] - 1),
        else: votes |> Map.put(current_user_id, votes[current_user_id] + 1)
    end)
  end

  # takes in trusted user's list (last) which is calculated in previous iteration of outer loop
  # iterates through each trusted user and updates: sources (accumulation of all trusted users),
  # untrusted (accumulation of all untrusted users), last (previous iterations trusted user list)
  # and debug (map containing debug info for trust sources)
  defp update_sources_untrusted_last_and_debug(acc, votes, current_trust_list_data, i, debug) do
    Enum.reduce(
      current_trust_list_data,
      %{sources: acc.sources, untrusted: acc.untrusted, last: [], debug: debug},
      fn trust, acc ->
        current_user_id = trust.user_id_trusted
        current_user_votes = votes[current_user_id]

        debug =
          if acc.debug and !acc.untrusted[current_user_id] do
            debug_i_len_enum = 0..(length(acc.debug[i]) - 1) |> Enum.to_list()

            exists =
              Enum.filter(debug_i_len_enum, fn n ->
                Enum.at(acc.debug[i], n) == current_user_id
              end)
              |> length > 0

            updated_debug_i =
              if exists,
                do: acc.debug[i],
                else: acc.debug[i] ++ [[current_user_id, current_user_votes]]

            Map.put(acc.debug, i, updated_debug_i)
          end

        # current user is trusted if votes is 0 (neutral) or greater
        # and current user isn't in truster user's untrusted list
        trusted_source = votes[current_user_id] >= 0 and !acc.untrusted[current_user_id]

        # sources is all trusted user so far based on truster user's trust list (or default trust list if no list)
        sources =
          if trusted_source,
            do: acc.sources ++ [current_user_id],
            else: acc.sources

        # last is the current user's trusted users, unlike sources which is all trusted user's so far
        last =
          if trusted_source,
            do: acc.last ++ [current_user_id],
            else: acc.last

        # untrusted is a list of all untrusted users so far
        untrusted =
          if trusted_source,
            do: acc.untrusted,
            else: Map.put(acc.untrusted, current_user_id, 1)

        %{
          sources: sources,
          untrusted: untrusted,
          last: last,
          debug: debug
        }
      end
    )
  end

  # If the user has no trust list, this will default to use Default Trust User's trust list instead. Only runs on
  # initial iteration of outer most loop on max_depth, subsequent runs variables are just passed back
  defp maybe_use_default_trust_list(sources, last, votes, debug, i) do
    # if initial iteration finishes and there are no users in last array or votes, user has no trust list
    no_trusted_sources = last == [] and i == 0 and Map.keys(votes) == []

    # get default trust user id if user has no trust list
    default_trust_user_id = if no_trusted_sources, do: User.get_default_trust_user_id()

    sources = if no_trusted_sources, do: sources ++ [default_trust_user_id], else: sources

    last = if no_trusted_sources, do: last ++ [default_trust_user_id], else: last

    debug =
      if no_trusted_sources and debug,
        do: Map.put(debug, 0, Enum.at(debug, 0) ++ [[default_trust_user_id, 0]])

    %{
      sources: sources,
      last: last,
      debug: debug
    }
  end
end
