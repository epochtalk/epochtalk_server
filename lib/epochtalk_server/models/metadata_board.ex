defmodule EpochtalkServer.Models.MetadataBoard do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User
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

  @doc """
  Queries then updates `MetadataBoard` info for the specified Board`
  """
  @spec update_last_post_info(metadata_board :: t(), board_id :: non_neg_integer) :: t()
  def update_last_post_info(metadata_board, board_id) do
    # query most recent post in thread and it's authoring user's data
    last_post_query =
      from t in Thread,
        left_join: p in Post,
        on: t.id == p.thread_id,
        left_join: u in User,
        on: u.id == p.user_id,
        where: t.board_id == ^board_id,
        order_by: [desc: p.created_at],
        limit: 1,
        select: %{
          thread_id: p.thread_id,
          created_at: p.created_at,
          username: u.username,
          position: p.position
        }

    # query most recent thread in board title
    last_post_info =
      if lp = Repo.one(last_post_query) do
        last_thread_title_query =
          from p in Post,
            where: p.thread_id == ^lp.thread_id,
            order_by: [asc: p.created_at],
            limit: 1,
            select: p.content["title"]

        last_thread_title = Repo.one(last_thread_title_query)

        %{
          last_post_username: lp.username,
          last_post_created_at: lp.created_at,
          last_thread_id: lp.thread_id,
          last_thread_title: last_thread_title,
          last_post_position: lp.position
        }
      else
        %{
          last_post_username: nil,
          last_post_created_at: nil,
          last_thread_id: nil,
          last_thread_title: nil,
          last_post_position: nil
        }
      end

    # update board metadata using queried data
    updated_metadata_board = change(metadata_board, last_post_info)

    Repo.update!(updated_metadata_board)
  end
end
