defmodule EpochtalkServer.Models.Trust do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Trust
  alias EpochtalkServer.Models.User

  @moduledoc """
  `Trust` model, for performing actions relating to `Trust`
  """
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
  Calculates the set of users in a user's `Trust` network, `max_depth` is codnfigured by the user
  """
  @spec trust_sources_by_user_id(user_id :: non_neg_integer, max_depth :: non_neg_integer, debug :: []) :: [non_neg_integer]
  def trust_sources_by_user_id(user_id, max_depth, debug) do
    depth = 0..max_depth - 1 |> Enum.to_list()
    %{sources: sources, untrusted: _untrusted, last: _last, debug: debug} =
      Enum.reduce(depth, %{sources: [], untrusted: %{}, last: [user_id], debug: debug}, fn i, acc ->
        debug = if acc.debug, do: Map.put(acc.debug, i, [])

        if acc.last == [] do
          # do nothing
          acc
        else
          trust_info = trust_by_user_ids(acc.last)

          trust_info_len_enum = 0..length(trust_info) - 1 |> Enum.to_list()

          votes = Enum.reduce(trust_info_len_enum, %{}, fn x, acc ->
            cur = Enum.at(trust_info, x)
            cur_id = cur.user_id_trusted
            acc = if is_nil(acc[cur_id]), do: Map.put(acc, cur_id, 0), else: acc
            if cur.type == 1,
              do: Map.put(acc, cur_id, acc[cur_id] - 1),
              else: Map.put(acc, cur_id, acc[cur_id] + 1)
          end)

          %{sources: sources, untrusted: untrusted, last: last, debug: debug} =
            Enum.reduce(trust_info_len_enum, %{sources: acc.sources, untrusted: acc.untrusted, last: [], debug: debug}, fn y, acc ->
              cur_id = Enum.at(trust_info, y).user_id_trusted
              cur_votes = votes[cur_id]

              debug = if acc.debug and !acc.untrusted[cur_id] do
                debug_i_len_enum = 0..length(acc.debug[i]) - 1 |> Enum.to_list()
                exists = Enum.filter(debug_i_len_enum, fn n -> Enum.at(acc.debug[i], n) == cur_id end) |> length > 0
                updated_debug_i = if exists, do: acc.debug[i], else: acc.debug[i] ++ [[cur_id, cur_votes]]
                Map.put(acc.debug, i, updated_debug_i)
              end

              trusted_source = votes[cur_id] >= 0 and !acc.untrusted[cur_id]

              sources = if trusted_source,
                do: acc.sources ++ [cur_id],
                else: acc.sources

              last = if trusted_source,
                do: acc.last ++ [cur_id],
                else: acc.last

              untrusted = if trusted_source,
                do: acc.untrusted,
                else: Map.put(acc.untrusted, cur_id, 1)

              %{
                sources: sources,
                untrusted: untrusted,
                last: last,
                debug: debug
              }
            end)

          no_trusted_sources = last == [] and i == 0 and Map.keys(votes) == []

          default_trust_user_id = if no_trusted_sources, do: User.get_default_trust_user_id()

          sources = if no_trusted_sources,
            do: sources ++ [default_trust_user_id],
            else: sources

          last = if no_trusted_sources,
            do: last ++ [default_trust_user_id],
            else: last

          debug = if no_trusted_sources and debug do
            Map.put(debug, 0, Enum.at(debug, 0) ++ [[default_trust_user_id, 0]])
          end

          %{
            sources: sources,
            untrusted: untrusted,
            last: last,
            debug: debug
          }
        end
      end)

    sources = Enum.uniq(sources ++ [user_id])

    debug = if debug, do: Map.put(debug, 0, Enum.at(debug, 0) ++ [[user_id, 0]]) |> Logger.debug()

    sources
  end
end
