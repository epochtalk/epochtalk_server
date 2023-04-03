defmodule EpochtalkServer.Models.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Profile

  @moduledoc """
  `Profile` model, for performing actions relating a user's profile
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          user_id: non_neg_integer | nil,
          avatar: String.t() | nil,
          position: String.t() | nil,
          signature: String.t() | nil,
          raw_signature: String.t() | nil,
          post_count: non_neg_integer | nil,
          fields: map() | nil,
          last_active: NaiveDateTime.t() | nil
        }
  @schema_prefix "users"
  schema "profiles" do
    belongs_to :user, User
    field :avatar, :string
    field :position, :string
    field :signature, :string
    field :raw_signature, :string
    field :post_count, :integer, default: 0
    field :fields, :map
    field :last_active, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Creates a changeset for `Profile` model
  """
  @spec changeset(profile :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [
      :user_id,
      :avatar,
      :position,
      :signature,
      :raw_signature,
      :fields
    ])
    |> validate_required([:user_id])
  end

  ## === Database Functions ===

  @doc """
  Increments the `post_count` field given a `User` id
  """
  @spec increment_post_count(user_id :: non_neg_integer) :: {non_neg_integer(), nil}
  def increment_post_count(user_id) do
    query = from p in Profile, where: p.user_id == ^user_id
    Repo.update_all(query, inc: [post_count: 1])
  end

  @doc """
  Creates `Profile` record for a specific `User`
  """
  @spec create(user_id :: non_neg_integer, attrs :: map | nil) ::
          {:ok, profile :: t()} | {:error, Ecto.Changeset.t()}
  def create(user_id, attrs \\ %{}),
    do: changeset(%Profile{user_id: user_id}, attrs) |> Repo.insert(returning: true)

  @doc """
  Upserts `Profile` record for a specific `User`
  """
  @spec upsert(user_id :: non_neg_integer, attrs :: map | nil) ::
          {:ok, profile :: t()} | {:error, Ecto.Changeset.t()}
  def upsert(user_id, attrs \\ %{}) do
    if db_profile = Repo.get_by(Profile, user_id: user_id),
      do: db_profile |> changeset(attrs) |> Repo.update(),
      else: create(user_id, attrs)
  end
end
