defmodule EpochtalkServer.Models.MetadataBoards do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.Board

  @schema_prefix "metadata"
  schema "boards" do
    belongs_to :board, Board
    field :post_count, :integer
    field :thread_count, :integer
    field :total_post, :integer
    field :total_thread_count, :integer
    field :last_post_username, :string
    field :last_post_created_at, :naive_datetime
    field :last_thread_id, :integer
    field :last_thread_title, :string
    field :last_post_position, :integer
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:id, :board_id, :post_count, :thread_count,
      :total_post, :total_thread_count, :last_post_username,
      :last_post_created_at, :last_thread_id, :last_thread_title,
      :last_post_position])
    |> validate_required([:board_id])
  end
end
