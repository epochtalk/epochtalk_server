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

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :board_id])
    |> validate_required([:user_id, :board_id])
  end

  defp get_boards_by_user_id(user_id) when is_integer(user_id) do
    from(bm in BoardModerator, where: bm.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(&(&1.board_id))
  end

  def get_boards(%{ id: user_id } = user) do
    moderating = get_boards_by_user_id(user_id)
    if length(moderating) > 1,
      do: {:ok, Map.put(user, :moderating, moderating)},
      else: {:ok, user}
  end
end
