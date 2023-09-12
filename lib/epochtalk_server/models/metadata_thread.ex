defmodule EpochtalkServer.Models.MetadataThread do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.MetadataThread

  @moduledoc """
  `MetadataThread` model, for performing actions relating to `Board` metadata
  """

  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          thread: Thread.t() | term(),
          views: non_neg_integer | nil
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :thread_id,
             :views
           ]}
  @schema_prefix "metadata"
  schema "threads" do
    belongs_to :thread, Thread
    field :views, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for inserting a new `MetadataThread` model
  """
  @spec changeset(
          metadata_thread :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(metadata_thread, attrs \\ %{}) do
    metadata_thread
    |> cast(attrs, [
      :id,
      :thread_id,
      :views
    ])
    |> validate_required([:thread_id])
  end

  ## === Database Functions ===

  @doc """
  Inserts a new `MetadataThread` into the database
  """
  @spec insert(metadata_thread :: t()) ::
          {:ok, metadata_thread :: t()} | {:error, Ecto.Changeset.t()}
  def insert(%MetadataThread{} = metadata_thread), do: Repo.insert(metadata_thread)

  @doc """
  Increments a thread's view count by incrementing `views` field in associated `MetadataThread` model
  """
  @spec increment_view_count(thread_id :: non_neg_integer) :: {non_neg_integer(), nil}
  def increment_view_count(thread_id) when is_integer(thread_id) do
    query = from mt in MetadataThread, where: mt.thread_id == ^thread_id
    Repo.update_all(query, inc: [views: 1])
  end
end
