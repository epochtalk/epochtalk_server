defmodule EpochtalkServer.Models.Trust do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Trust
  alias EpochtalkServer.Models.User

  @moduledoc """
  `Trust` model, for performing actions relating to `Trust`
  """
  @type t :: %__MODULE__{
    user_id: non_neg_integer | nil,
    user_id_trusted: non_neg_integer | nil,
    type: non_neg_integer | nil
  }
  @derive {Jason.Encoder, only: [:user_id, :user_id_trusted, :type]}
  @primary_key false
  schema "trust" do
    belongs_to :user, User
    belongs_to :trusted_user_id, User, foreign_key: :user_id_trusted
    field :type, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `Trust` model
  """
  @spec changeset(
          trust :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(trust, attrs \\ %{}) do
    trust
    |> cast(attrs, [:user_id, :user_id_trusted, :type])
    |> validate_required([:user_id, :user_id_trusted, :type])
  end

  ## === Database Functions ===

  @doc """
  Query all `Trust` models
  """
  @spec trust_by_user_id(trusted :: [non_neg_integer]) :: [Ecto.Changeset.t()]
  def trust_by_user_ids(trusted) do
    query =
      from t in Trust,
      where: t.user_id in ^trusted

    Repo.all(query)
  end
end
