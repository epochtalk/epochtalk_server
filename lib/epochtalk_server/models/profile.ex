defmodule EpochtalkServer.Models.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Profile

  @schema_prefix "users"
  schema "profiles" do
    belongs_to :user_id, User
    field :avatar, :string
    field :position, :string
    field :signature, :string
    field :raw_signature, :string
    field :post_count, :integer, default: 0
    field :fields, :map
    field :last_active, :naive_datetime
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :avatar, :position, :signature, :raw_signature, :post_count, :field, :last_active])
    |> validate_required([:user_id])
  end
end
