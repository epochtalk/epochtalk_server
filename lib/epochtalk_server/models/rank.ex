defmodule EpochtalkServer.Models.Rank do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Rank

  @moduledoc """
  `Rank` model, for performing actions relating to `User` `Rank`
  """
  @type t :: %__MODULE__{
          name: String.t() | nil,
          number: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:name, :number]}
  @primary_key false
  schema "ranks" do
    field :name, :string
    field :number, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `Rank` model
  """
  @spec changeset(
          rank :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(rank, attrs \\ %{}) do
    rank
    |> cast(attrs, [:name, :number])
    |> validate_required([:name, :number])
  end

  ## === Database Functions ===

  @doc """
  Query all `Rank` models
  """
  @spec all() :: [Ecto.Changeset.t()] | nil
  def all(), do: Repo.all(from Rank)
end
