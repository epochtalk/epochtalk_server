defmodule EpochtalkServer.Models.BoardModerator do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.BoardModerator

  @moduledoc """
  `BoardModerator` model, for performing actions relating to `Board` moderators
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer,
          board_id: non_neg_integer
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :board_id
           ]}
  @primary_key false
  schema "board_moderators" do
    belongs_to :user, User
    belongs_to :board, Board
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `BoardModerator` model
  """
  @spec changeset(
          board_moderator :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(board_moderator, attrs \\ %{}) do
    board_moderator
    |> cast(attrs, [:user_id, :board_id])
    |> validate_required([:user_id, :board_id])
  end

  ## === Database Functions ===

  @doc """
  Query all `BoardModerator` models
  """
  @spec all() :: [Ecto.Changeset.t()] | nil
  def all(), do: Repo.all(from BoardModerator, preload: [user: ^from(User, select: [:username])])

  @doc """
  Returns list containing zero or more `board_id` corresponding to a `Board` that the specified `User` moderates
  """
  @spec get_user_moderated_boards(user_id :: non_neg_integer) :: [Ecto.Changeset.t()] | []
  def get_user_moderated_boards(user_id),
    do: Repo.all(from(b in BoardModerator, select: b.board_id, where: b.user_id == ^user_id))

  @doc """
  Check if a specific `User` is moderater of a `Board` using a `Board` ID
  """
  @spec user_is_moderator(
          board_id :: non_neg_integer,
          user_id :: non_neg_integer
        ) ::
          boolean
  def user_is_moderator(board_id, user_id) do
    query =
      from bm in BoardModerator,
        where: bm.user_id == ^user_id and bm.board_id == ^board_id,
        select: bm.user_id

    Repo.exists?(query)
  end

  @doc """
  Check if a specific `User` is moderater of a `Board` using a `Thread` ID
  """
  @spec user_is_moderator_with_thread_id(thread_id :: non_neg_integer, user_id :: non_neg_integer) ::
          boolean
  def user_is_moderator_with_thread_id(thread_id, user_id) do
    query =
      from bm in BoardModerator,
        left_join: b in Board,
        on: bm.board_id == b.id,
        left_join: t in Thread,
        on: b.id == t.board_id,
        where: bm.user_id == ^user_id and t.id == ^thread_id,
        select: bm.user_id

    Repo.exists?(query)
  end

  @doc """
  Check if a specific `User` is moderater of a `Board` using a `Post` ID
  """
  @spec user_is_moderator_with_post_id(
          post_id :: non_neg_integer,
          user_id :: non_neg_integer
        ) ::
          boolean
  def user_is_moderator_with_post_id(post_id, user_id) do
    query =
      from bm in BoardModerator,
        left_join: b in Board,
        on: bm.board_id == b.id,
        left_join: t in Thread,
        on: b.id == t.board_id,
        left_join: p in Post,
        on: p.thread_id == t.id,
        where: bm.user_id == ^user_id and p.id == ^post_id,
        select: bm.user_id

    Repo.exists?(query)
  end

  @doc """
  Adds list of users to the list of moderators for a specific `Board`
  """
  @spec add_moderators_by_username(
          board_id :: non_neg_integer,
          usernames :: [String.t()]
        ) ::
          {:ok, added_moderators :: [User.t()] | []}
  def add_moderators_by_username(board_id, usernames)
      when is_integer(board_id) and is_list(usernames) do
    Repo.transaction(fn ->
      # fetches all users in list with role data attached for return
      users = User.by_usernames(usernames)

      # insert each board moderator
      Enum.each(users, fn user ->
        Repo.insert(
          %BoardModerator{user_id: user.id, board_id: board_id},
          on_conflict: :nothing,
          conflict_target: [:user_id, :board_id]
        )
      end)

      # return users upon successfully adding new moderators
      users
    end)
  end

  @doc """
  Removes list of users from the list of moderators for a specific `Board`
  """
  @spec remove_moderators_by_username(
          board_id :: non_neg_integer,
          usernames :: [String.t()]
        ) ::
          {:ok, removed_moderators :: [User.t()] | []}
  def remove_moderators_by_username(board_id, usernames)
      when is_integer(board_id) and is_list(usernames) do
    Repo.transaction(fn ->
      # fetches all users in list with role data attached for return
      users = User.by_usernames(usernames)

      user_ids = Enum.map(users, & &1.id)

      # remove board moderators
      query =
        from bm in BoardModerator,
          where: bm.board_id == ^board_id and bm.user_id in ^user_ids

      Repo.delete_all(query)

      # return users upon successfully adding new moderators
      users
    end)
  end
end
