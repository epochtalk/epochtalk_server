defmodule EpochtalkServer.Models.BoardModerator do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.BoardModerator

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
