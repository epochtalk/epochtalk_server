defmodule EpochtalkServer.Models.MetricRankMap do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.MetricRankMap

  @moduledoc """
  `MetricRankMap` model, for performing actions relating to `MetricRankMap`
  """
  @type t :: %__MODULE__{maps: map() | nil}
  @derive {Jason.Encoder, only: [:maps]}
  @primary_key false
  schema "metric_rank_maps" do
    field :maps, :map
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `MetricRankMap` model
  """
  @spec changeset(
          rank_map :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(rank_map, attrs \\ %{}) do
    rank_map
    |> cast(attrs, [:maps])
    |> validate_required([:maps])
  end

  ## === Database Functions ===

  @doc """
  Query and merge all `MetricRankMap` models
  """
  @spec all_merged() :: [Ecto.Changeset.t()] | nil
  def all_merged(), do: Repo.all(from(MetricRankMap)) |> Enum.reduce(&Map.merge/2)
end
