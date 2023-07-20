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
end
