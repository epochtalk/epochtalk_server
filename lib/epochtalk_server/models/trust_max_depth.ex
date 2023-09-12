defmodule EpochtalkServer.Models.TrustMaxDepth do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.TrustMaxDepth

  @default_max_depth 2

  @moduledoc """
  `TrustMaxDepth` model, for performing actions relating to `TrustMaxDepth`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          max_depth: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:user_id, :max_depth]}
  @primary_key false
  schema "trust_max_depth" do
    belongs_to :user, User
    field :max_depth, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `TrustMaxDepth` model
  """
  @spec changeset(
          trust_max_depth :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(trust_max_depth, attrs \\ %{}) do
    trust_max_depth
    |> cast(attrs, [:user_id, :max_depth])
    |> validate_required([:user_id, :max_depth])
  end

  @doc """
  Gets `max_depth` record for a specific `User`, defaults to `max_depth` of `2` if
  `User` doesn't have `max_depth` set or if the it is outside the range 0-4
  """
  @spec by_user_id(user_id :: non_neg_integer) ::
          max_depth :: non_neg_integer | nil
  def by_user_id(user_id) do
    query = from t in TrustMaxDepth, where: t.user_id == ^user_id, select: t.max_depth
    max_depth = Repo.one(query)
    if max_depth in 0..4, do: max_depth, else: @default_max_depth
  end
end
