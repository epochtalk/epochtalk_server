defmodule EpochtalkServer.Models.MetadataBoard do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.MetadataBoard
 @moduledoc """
  `MetadataBoard` model, for performing actions relating to `Board` metadata
  """

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

  ## === Changesets Functions ===

  @doc """
  Create changeset for inserting a new `MetadataBoard` model
  """
  @spec changeset(
    metadata_board :: %EpochtalkServer.Models.MetadataBoard{},
    attrs :: %{} | nil
  ) :: %EpochtalkServer.Models.MetadataBoard{}
  def changeset(metadata_board, attrs \\ %{}) do
    metadata_board
    |> cast(attrs, [:id, :board_id, :post_count, :thread_count,
      :total_post, :total_thread_count, :last_post_username,
      :last_post_created_at, :last_thread_id, :last_thread_title,
      :last_post_position])
    |> validate_required([:board_id])
  end

  ## === Database Functions ===

  @doc """
  Inserts a new `MetadataBoard` into the database
  """
  @spec insert(
    metadata_board :: %EpochtalkServer.Models.MetadataBoard{}
  ) :: {:ok, metadata_board :: %EpochtalkServer.Models.MetadataBoard{}} | {:error, Ecto.Changeset.t()}
  def insert(%MetadataBoard{} = metadata_board), do: Repo.insert(metadata_board)
end
