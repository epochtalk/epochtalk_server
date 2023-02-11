defmodule EpochtalkServer.Models.Thread do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Thread
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
  def recent(user, user_priority, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    IO.inspect user
    IO.inspect user_priority
    query = from Thread,
      order_by: [desc: :updated_at],
      limit: ^limit

    Repo.all(query)
  end
end
