defmodule EpochtalkServer.Models.Thread do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.MetadataThread
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post

  @moduledoc """
  `Thread` model, for performing actions relating to forum threads
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          board_id: non_neg_integer | nil,
          locked: boolean | nil,
          sticky: boolean | nil,
          slug: String.t() | nil,
          moderated: boolean | nil,
          post_count: non_neg_integer | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema "threads" do
    belongs_to :board, Board
    field :locked, :boolean
    field :sticky, :boolean
    field :slug, :string
    field :moderated, :boolean
    field :post_count, :integer
    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    has_many :posts, Post
    # field :smf_topic, :map, virtual: true
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Thread` model
  """
  @spec changeset(thread :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [
      :id,
      :board_id,
      :locked,
      :sticky,
      :slug,
      :moderated,
      :post_count,
      :created_at,
      :imported_at,
      :updated_at
    ])
    |> unique_constraint(:id, name: :threads_pkey)
    |> unique_constraint(:slug, name: :threads_slug_index)
    |> foreign_key_constraint(:board_id, name: :threads_board_id_fkey)
  end

  ## === Database Functions ===

  @doc """
  Returns recent threads accounting for user priority and user's ignored boards
  """
  @spec recent(user :: User.t(), user_priority :: non_neg_integer, opts :: list() | nil) :: [t()]
  def recent(_user, _user_priority, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    # IO.inspect user
    # IO.inspect user_priority
    query =
      from Thread,
        order_by: [desc: :updated_at],
        limit: ^limit

    Repo.all(query)
  end

  def page_by_board_id(board_id, page \\ 1, opts \\ []) do
    user_id = Keyword.get(opts, :user_id)
    per_page = Keyword.get(opts, :per_page, 25)
    field = Keyword.get(opts, :field, "updated_at")
    reversed = Keyword.get(opts, :desc, false)
    offset = (page * opts[:per_page]) - opts[:per_page];

    opts = opts
      |> Keyword.put(:user_id, user_id)
      |> Keyword.put(:per_page, per_page)
      |> Keyword.put(:field, field)
      |> Keyword.put(:reversed, reversed)
      |> Keyword.put(:offset, offset)

    %{
      sticky: sticky_by_board_id(board_id, page, opts),
      normal: normal_by_board_id(board_id, page, opts)
    }
  end

  def sticky_by_board_id(board_id, page, opts) when page == 1 do
    field = String.to_atom(opts[:field])
    direction = if opts[:reversed], do: :desc, else: :asc
    subquery = Thread
    |> join(:left, [t], mt in MetadataThread, on: t.id == mt.thread_id)
    |> where([t, mt], t.board_id == ^board_id and t.sticky == true and not is_nil(t.updated_at))
    |> select([t, mt], %{board_id: t.board_id, updated_at: t.updated_at, views: mt.views, created_at: t.created_at, post_count: t.post_count})
    |> limit(^opts[:per_page])
    |> offset(^opts[:offset])

    subquery = if field == :views,
      do: subquery |> order_by([t, mt], [{^direction, mt.views}]),
      else: subquery |> order_by([t], [{^direction, field(t, ^field)}])
    Repo.all(subquery)
  end
  def sticky_by_board_id(_board_id, page, _opts) when page != 1, do: []

  defp normal_by_board_id(_board_id, _page, _opts) do
  end
end
