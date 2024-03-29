defmodule EpochtalkServer.Models.MetadataBoard do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.MetadataBoard

  @moduledoc """
  `MetadataBoard` model, for performing actions relating to `Board` metadata
  """

  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          board: Board.t() | term(),
          post_count: non_neg_integer | nil,
          thread_count: non_neg_integer | nil,
          total_post: non_neg_integer | nil,
          total_thread_count: non_neg_integer | nil,
          last_post_username: String.t() | nil,
          last_post_created_at: NaiveDateTime.t() | nil,
          last_thread_id: non_neg_integer | nil,
          last_thread_title: String.t() | nil,
          last_post_position: non_neg_integer | nil
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :board_id,
             :post_count,
             :thread_count,
             :total_post,
             :total_thread_count,
             :last_post_username,
             :last_post_created_at,
             :last_thread_id,
             :last_thread_title,
             :last_post_position
           ]}
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
          metadata_board :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(metadata_board, attrs \\ %{}) do
    metadata_board
    |> cast(attrs, [
      :id,
      :board_id,
      :post_count,
      :thread_count,
      :total_post,
      :total_thread_count,
      :last_post_username,
      :last_post_created_at,
      :last_thread_id,
      :last_thread_title,
      :last_post_position
    ])
    |> validate_required([:board_id])
  end

  ## === Database Functions ===

  @doc """
  Inserts a new `MetadataBoard` into the database
  """
  @spec insert(metadata_board :: t()) ::
          {:ok, metadata_board :: t()} | {:error, Ecto.Changeset.t()}
  def insert(%MetadataBoard{} = metadata_board), do: Repo.insert(metadata_board)
end
