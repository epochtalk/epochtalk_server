defmodule EpochtalkServer.Models.TrustMaxDepth do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User

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
end
