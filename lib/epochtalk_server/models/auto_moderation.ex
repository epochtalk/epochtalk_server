defmodule EpochtalkServer.Models.AutoModeration do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.AutoModeration

  @postgres_varchar255_max 255
  @postgres_varchar1000_max 1000

  @moduledoc """
  `AutoModeration` model, for performing actions relating to `User` `AutoModeration`
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          message: String.t() | nil,
          conditions: map | nil,
          actions: map | nil,
          options: map | nil,
          created_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :description,
             :message,
             :conditions,
             :actions,
             :options,
             :created_at,
             :updated_at
           ]}
  schema "auto_moderation" do
    field :name, :string
    field :description, :string
    field :message, :string
    field :conditions, :map
    field :actions, :map
    field :options, :map
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for `AutoModeration` model
  """
  @spec create_changeset(
          auto_moderation :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(auto_moderation, attrs \\ %{}) do
    auto_moderation
    |> cast(attrs, [
      :id,
      :name,
      :description,
      :message,
      :conditions,
      :actions,
      :options,
      :created_at,
      :updated_at
    ])
    |> unique_constraint(:id, name: :auto_moderation_pkey)
    |> validate_required([:name, :conditions, :actions])
    |> validate_length(:name, min: 1, max: @postgres_varchar255_max)
    |> validate_length(:description, max: @postgres_varchar1000_max)
    |> validate_length(:message, max: @postgres_varchar1000_max)
  end

  @doc """
  Creates an update changeset for `AutoModeration` model
  """
  @spec update_changeset(auto_moderation :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def update_changeset(auto_moderation, attrs \\ %{}) do
    updated_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    auto_moderation =
      auto_moderation
      |> Map.put(:updated_at, updated_at)

    auto_moderation
    |> cast(attrs, [
      :id,
      :name,
      :description,
      :message,
      :conditions,
      :actions,
      :options,
      :created_at,
      :updated_at
    ])
    |> validate_required([
      :id,
      :name,
      :conditions,
      :actions,
      :updated_at
    ])
  end

  ## === Database Functions ===

  @doc """
  Get all `AutoModeration` rules
  """
  @spec all() :: [t()]
  def all() do
    query = from(a in AutoModeration)
    Repo.all(query)
  end

  @doc """
  Add `AutoModeration` rule
  """
  @spec add(auto_moderation_attrs :: map()) :: auto_moderation_rule :: t()
  def add(auto_moderation_attrs) do
    auto_moderation_cs = create_changeset(%AutoModeration{}, auto_moderation_attrs)
    Repo.insert(auto_moderation_cs)
  end

  @doc """
  Remove `AutoModeration` rule
  """
  @spec remove(id :: non_neg_integer) :: {non_neg_integer(), nil | [term()]}
  def remove(id) do
    query =
      from a in AutoModeration,
        where: a.id == ^id

    Repo.delete_all(query)
  end

  @doc """
  Updates an existing `AutoModeration` rule in the database and reloads role cache
  """
  @spec update(auto_moderation_attrs :: map()) ::
          {:ok, auto_moderation :: Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(auto_moderation_attrs) do
    AutoModeration
    |> Repo.get(auto_moderation_attrs["id"])
    |> update_changeset(auto_moderation_attrs)
    |> Repo.update()
  end
end
