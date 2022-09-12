defmodule EpochtalkServer.Models.BoardModerators do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board

  @primary_key false
  schema "board_moderators" do
    belongs_to :user_id, User
    belongs_to :board_id, Board
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :board_id])
    |> validate_required([:user_id, :board_id])
  end
end
