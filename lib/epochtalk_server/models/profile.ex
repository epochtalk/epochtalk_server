defmodule EpochtalkServer.Models.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  @moduledoc """
  `Profile` model, for performing actions relating a user's profile
  """

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
  Creates a generic changeset for `Profile` model
  """
  @spec changeset(
    profile :: %EpochtalkServer.Models.Profile{},
    attrs :: %{} | nil
  ) :: %EpochtalkServer.Models.Profile{}
  def changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [:user_id, :avatar, :position, :signature, :raw_signature, :post_count, :field, :last_active])
    |> validate_required([:user_id])
  end
end
