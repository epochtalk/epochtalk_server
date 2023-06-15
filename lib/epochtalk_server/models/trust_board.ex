defmodule EpochtalkServer.Models.TrustBoard do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.TrustBoard

  @moduledoc """
  `TrustBoard` model, for performing actions relating to `TrustBoard`
  """
  @type t :: %__MODULE__{board_id: non_neg_integer | nil}
  @derive {Jason.Encoder, only: [:board_id]}
  @primary_key false
  schema "trust_boards" do
    field :board_id, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `TrustBoard` model
  """
  @spec changeset(
          trust_board :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(trust_board, attrs \\ %{}) do
    trust_board
    |> cast(attrs, [:board_id])
    |> validate_required([:board_id])
  end

  ## === Database Functions ===

  @doc """
  Query all `TrustBoard` models
  """
  @spec all() :: [Ecto.Changeset.t()] | nil
  def all(), do: Repo.all(from TrustBoard)
end
