defmodule EpochtalkServer.Models.ImageReference do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ecto.Multi
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.ImageReference
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.Post
  # alias EpochtalkServer.Models.Message
  alias EpochtalkServer.S3

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
  @derive {Jason.Encoder, only: [:expiration, :created_at]}
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
    |> validate_required([:type])
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

    image_reference
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
  @spec create(attrs :: map()) ::
          {:ok, image_reference :: t(), ExAws.S3.presigned_post_result()}
          | {:error, Ecto.Changeset.t()}
  def create(attrs_list) when is_list(attrs_list) do
    # [changesets]
    image_reference_changesets =
      attrs_list
      |> Stream.with_index()
      |> Stream.map(fn {attrs, index} ->
        {create_changeset(%ImageReference{}, attrs), index}
      end)
      |> Stream.map(fn {image_reference_changeset, index} ->
        uuid = image_reference_changeset.changes.uuid
        insert_key = "image_reference_#{uuid}"
        presigned_post_key = "#{index}"

        Multi.new()
        |> Multi.insert(insert_key, image_reference_changeset)
        |> Multi.run(presigned_post_key, fn _repo, insert_result ->
          image_reference = insert_result[insert_key]
          # set presigned post parameters
          filename = image_reference.uuid <> "." <> image_reference.type

          # generate presigned post
          presigned_post_result = S3.generate_presigned_post(%{filename: filename})
          {:ok, presigned_post_result}
        end)
      end)
      # build multi combined transaction
      |> Enum.reduce(Multi.new(), &Multi.append/2)
      |> Repo.transaction()
      |> case do
        {:ok, results} ->
          results =
            results
            # return only indexed items
            |> Enum.filter(&key_is_integer?/1)
            |> Map.new()

          {:ok, results}

        {:error, :image_references, value, others} ->
          {:error, value, others}
      end
  end

  def create(attrs) do
    image_reference_changeset = create_changeset(%ImageReference{}, attrs)

    case Repo.insert(image_reference_changeset) do
      {:ok, image_reference} ->
        # set presigned post parameters
        filename = image_reference.uuid <> "." <> image_reference.type

        # generate presigned post
        presigned_post_result = S3.generate_presigned_post(%{filename: filename})
        {:ok, image_reference, presigned_post_result}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Finds an `ImageReference`
  """
  @spec find(image_reference_attrs :: map()) ::
          {:ok, image_reference :: t()} | {:error, Ecto.Changeset.t()}
  def find(image_reference) do
    Repo.all(image_reference)
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

  defp key_is_integer?({key, _}) do
    key
    |> Integer.parse()
    |> case do
      {_, ""} -> true
      _ -> false
    end
  end
end
