defmodule EpochtalkServer.Models.BoardBan do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.BoardBan
  alias EpochtalkServer.Models.Board

  @moduledoc """
  `BoardBan` model, for performing actions relating a user's profile
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          user_id: non_neg_integer | nil
        }
  @primary_key false
  @schema_prefix "users"
  schema "board_bans" do
    belongs_to :user, User
    belongs_to :board, Board
  end

  ## === Changesets Functions ===

  @doc """
  Creates a generic changeset for `BoardBan` model
  """
  @spec changeset(board_ban :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(board_ban, attrs \\ %{}) do
    board_ban
    |> cast(attrs, [
      :user_id,
      :board_id
    ])
    |> validate_required([:user_id, :board_id])
  end

  ## === Database Functions ===

  @doc """
  Used to check if `User` is banned from board.
  Accepts a `board_id`, `post_id` or `thread_id` as an option.

  Returns `true` if the user is banned from the specified `Board` or `false`
  otherwise.
  """
  @spec is_banned_from_board(user :: User.t(), opts :: list) :: {:ok, banned :: boolean}
  def is_banned_from_board(%{id: user_id} = _user, opts) when is_integer(user_id) do
    board_id = Keyword.get(opts, :board_id)
    post_id = Keyword.get(opts, :post_id)
    thread_id = Keyword.get(opts, :thread_id)

    query =
      cond do
        is_integer(board_id) ->
          from bb in BoardBan,
            where: bb.user_id == ^user_id and bb.board_id == ^board_id,
            select: bb.user_id

        is_integer(post_id) ->
          from bb in BoardBan,
            where:
              bb.user_id == ^user_id and
                bb.board_id ==
                  subquery(
                    from(p in Post,
                      left_join: t in Thread,
                      on: t.id == p.thread_id,
                      where: p.id == ^post_id,
                      select: t.board_id
                    )
                  ),
            select: bb.user_id

        is_integer(thread_id) ->
          from bb in BoardBan,
            where:
              bb.user_id == ^user_id and
                bb.board_id ==
                  subquery(from(t in Thread, where: t.id == ^thread_id, select: t.board_id)),
            select: bb.user_id

        true ->
          nil
      end

    result = if query, do: is_integer(Repo.one(query)), else: false
    {:ok, result}
  end

  def is_banned_from_board(nil, _opts), do: {:ok, false}

  @doc """
  Used to check if `User` with specified `user_id` is not banned from board.
  Accepts a `board_id`, `post_id` or `thread_id` as an option.

  Returns `true` if the user is **not** banned from the specified `Board` or `false`
  otherwise.
  """
  @spec is_not_banned_from_board(user :: User.t(), opts :: list) :: {:ok, not_banned :: boolean}
  def is_not_banned_from_board(user, opts \\ [])

  def is_not_banned_from_board(%{id: user_id} = user, opts) when is_integer(user_id) do
    {:ok, banned} = is_banned_from_board(user, opts)
    {:ok, !banned}
  end

  def is_not_banned_from_board(nil, _opts), do: {:ok, true}
end
