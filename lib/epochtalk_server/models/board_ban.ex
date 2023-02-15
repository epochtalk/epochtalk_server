defmodule EpochtalkServer.Models.BoardBan do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board

  @moduledoc """
  `BoardBan` model, for performing actions relating a user's profile
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          user_id: non_neg_integer | nil,
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
      :board_id,
    ])
    |> validate_required([:user_id, :board_id])
  end

  def all(), do: Repo.all(BoardBan)
end
