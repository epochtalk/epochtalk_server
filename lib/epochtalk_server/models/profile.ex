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
  Creates a generic changeset for `Profile` model
  """
  @spec changeset(profile :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [
      :id,
      :user_id,
      :avatar,
      :position,
      :signature,
      :raw_signature,
      :post_count,
      :field,
      :last_active
    ])
    |> validate_required([:id, :user_id])
  end

  @spec increment_post_count(user_id :: non_neg_integer) :: {non_neg_integer, nil}
  def increment_post_count(user_id) do
    query = from p in Profile, where: p.user_id == ^user_id
    Repo.update_all(query, inc: [post_count: 1])
  end
end
