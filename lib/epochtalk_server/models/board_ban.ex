defmodule EpochtalkServer.Models.BoardBan do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.BoardBan
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

  def is_banned_from_board(user_id, opts) do
    board_id = Keyword.get(opts, :board_id)
    query = from bb in BoardBan,
      where: bb.user_id == ^user_id and bb.board_id == ^board_id,
      select: bb.user_id
    if board_id, do: is_integer(Repo.one(query)), else: {:error, :board_does_not_exist}
  end

  def is_not_banned_from_board(user_id, opts), do: !is_banned_from_board(user_id, opts)
end
