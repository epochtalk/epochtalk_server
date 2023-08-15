defmodule EpochtalkServer.Models.AutoModeration do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  # alias EpochtalkServer.Repo
  # alias EpochtalkServer.Models.AutoModeration

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
  Generic changeset for `AutoModeration` model
  """
  @spec changeset(
          auto_moderation :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(auto_moderation, attrs \\ %{}) do
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
end
