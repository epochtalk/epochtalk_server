defmodule EpochtalkServer.Models.BoardModerator do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board

  @primary_key false
  schema "board_moderators" do
    belongs_to :user, User
    belongs_to :board, Board
  end

  ## === Changesets Functions ===

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :board_id])
    |> validate_required([:user_id, :board_id])
  end
end
