defmodule EpochtalkServer.Models.Thread do
  use Ecto.Schema
  import Ecto.Changeset
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
    |> cast(attrs, [:id, :board_id, :locked, :sticky, :slug, :moderated, :post_count, :created_at, :imported_at, :updated_at])
    |> unique_constraint(:id, name: :threads_pkey)
    |> unique_constraint(:slug, name: :threads_slug_index)
    |> foreign_key_constraint(:board_id, name: :threads_board_id_fkey)
  end
end
