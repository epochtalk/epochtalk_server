defmodule EpochtalkServer.Models.ImageReference do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Message

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
          post: Post.t() | term(),
          message: Message.t() | term(),
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
    many_to_many :post, Post, join_through: PostImageReference
    many_to_many :message, Message, join_through: MessageImageReference
    many_to_many :profile, Profile, join_through: ProfileImageReference
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
      :post,
      :message
    ])
    |> cast_assoc(:post)
    |> cast_assoc(:message)
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

    naive_datetime
    |> cast(attrs, [
      :uuid,
      :url,
      :length,
      :type,
      :checksum,
      :expiration,
      :created_at,
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
end
