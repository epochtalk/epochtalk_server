defmodule EpochtalkServer.Models.BoardModerator do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardModerator

  @primary_key false
  schema "board_moderators" do
    belongs_to :user, User
    belongs_to :board, Board
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :board_id])
    |> validate_required([:user_id, :board_id])
  end

  def get_boards(user_id) when is_integer(user_id) do
    Repo.all(BoardModerator, user_id: user_id)
    |> Enum.map(&(&1.board_id))
  end
end
