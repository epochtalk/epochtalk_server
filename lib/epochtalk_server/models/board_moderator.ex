defmodule EpochtalkServer.Models.BoardModerator do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardModerator

  @moduledoc """
  `BoardModerator` model, for performing actions relating to `Board` moderators
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer,
          board_id: non_neg_integer
        }
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

  def all(), do: Repo.all(from BoardModerator, preload: [user: ^from(User, select: [:username])])
end
