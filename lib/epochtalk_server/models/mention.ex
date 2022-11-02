defmodule EpochtalkServer.Models.Mention do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Mention
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.User

  @moduledoc """
  `Mention` model, for performing actions relating to forum categories
  """
  @type t :: %__MODULE__{
    id: non_neg_integer | nil,
    thread_id: non_neg_integer | nil,
    post_id: non_neg_integer | nil,
    mentioner_id: non_neg_integer | nil,
    mentionee_id: non_neg_integer | nil,
    created_at: NaiveDateTime.t() | nil
  }
  @schema_prefix "mentions"
  schema "mentions" do
    belongs_to :thread, Thread
    belongs_to :post, Post
    belongs_to :mentioner, User
    belongs_to :mentionee, User
    field :created_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Mention` model
  """
  @spec changeset(mention :: t(), attrs :: map() | nil) :: %Ecto.Changeset{}
  def changeset(mention, attrs) do
    mention
    |> cast(attrs, [:id, :thread_id, :post_id, :mentioner_id, :mentionee_id, :created_at])
    |> unique_constraint(:id, name: :mentions_pkey)
  end

end
