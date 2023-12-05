defmodule EpochtalkServer.Models.ImageReference do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.ImageReference
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.Post
  # alias EpochtalkServer.Models.Message

  @moduledoc """
  `ImageReference` model, for tracking images uploaded locally or to CDN
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          uuid: String.t() | nil,
          url: String.t() | nil,
          length: non_neg_integer | nil,
          type: String.t() | nil,
          checksum: String.t() | nil,
          expiration: NaiveDateTime.t() | nil,
          posts: [Post.t()] | term(),
          # messages: [Message.t()] | term(),
          profiles: [Profile.t()] | term(),
          created_at: NaiveDateTime.t() | nil
        }
  schema "image_references" do
    field :uuid, :string
    field :url, :string
    field :length, :integer
    field :type, :string
    field :checksum, :string
    field :expiration, :naive_datetime
    field :created_at, :naive_datetime
    many_to_many :posts, Post, join_through: PostImageReference
    # many_to_many :messages, Message, join_through: MessageImageReference
    many_to_many :profiles, Profile, join_through: ProfileImageReference
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `ImageReference` model
  """
  @spec changeset(
          image_reference :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(image_reference, attrs) do
    image_reference
    |> cast(attrs, [
      :id,
      :uuid,
      :url,
      :length,
      :type,
      :checksum,
      :expiration,
      :created_at,
      :posts,
      :messages,
      :profiles
    ])
    |> cast_assoc(:posts)
    |> cast_assoc(:messages)
    |> cast_assoc(:profiles)
  end

  @doc """
  Changeset for creating `ImageReference` model
  """
  @spec create_changeset(image_reference :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(image_reference, attrs) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    uuid = Ecto.UUID.generate()

    attrs =
      attrs
      |> Map.put(:created_at, now)
      |> Map.put(:uuid, uuid)

    now
    |> cast(attrs, [
      :uuid,
      :url,
      :length,
      :type,
      :checksum,
      :expiration,
      :created_at
    ])
    |> unique_constraint(:id, name: :image_references_pkey)
    |> unique_constraint(:checksum)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `ImageReference`
  """
  @spec create(image_reference_attrs :: map()) :: {:ok, image_reference :: t()} | {:error, Ecto.Changeset.t()}
  def create(image_reference) do
    image_reference_changeset = create_changeset(%ImageReference{}, image_reference)
    Repo.insert(image_reference_changeset)
  end

  @doc """
  Finds an `ImageReference`
  """
  @spec find(image_reference_attrs :: map()) :: {:ok, image_reference :: t()} | {:error, Ecto.Changeset.t()}
  def find(image_reference) do
    Repo.all(image_reference_changeset)
  end

  defp query_expired() do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    from i in ImageReference,
      where: i.expiration < ^now and i.posts == [] and i.messages == [] and i.profiles == []
  end

  @doc """
  Finds expired `ImageReference`s
  Images are expired if they are past their expiration date/time and have no referencing models
  """
  @spec find_expired() :: map()
  def find_expired() do
    query_expired()
    |> Repo.all()
  end

  @doc """
  Deletes expired `ImageReference`s
  Images are expired if they are past their expiration date/time and have no referencing models
  """
  @spec delete_expired() :: {non_neg_integer(), nil | [term()]}
  def delete_expired() do
    query_expired()
    |> Repo.delete_all()
  end

  @doc """
  Finds an `ImageReference` with specified uuid
  """
  @spec with_uuid(uuid :: String.t()) ::
          {:ok, t()} | {:error, :image_reference_does_not_exist}
  def with_uuid(uuid) when is_binary(uuid) do
    query = from i in ImageReference, where: i.uuid == ^uuid
    image_reference = Repo.one(query)

    if image_reference,
      do: {:ok, image_reference},
      else: {:error, :image_reference_does_not_exist}
  end
end
