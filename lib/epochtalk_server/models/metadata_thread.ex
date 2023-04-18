defmodule EpochtalkServer.Models.MetadataThread do
  use Ecto.Schema
  import Ecto.Changeset
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
end
