defmodule EpochtalkServer.Models.Configuration do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Configuration
 @moduledoc """
  `Configuration` model, for performing actions relating to frontend `Configuration`
  """

  @type t :: %__MODULE__{
    id: non_neg_integer | nil,
    name: String.t() | nil,
    config: map() | nil
  }
  schema "configurations" do
    field :name, :string
    field :config, :map
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for creating a new `Configuration` model
  """
  @spec create_changeset(
    configuration :: t(),
    attrs :: map() | nil
  ) :: %Ecto.Changeset{}
  def create_changeset(configuration, attrs \\ %{}) do
    configuration
    |> cast(attrs, [:name, :config])
    |> validate_required([:name, :config])
    |> unique_constraint(:name)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `Configuration` into the database
  """
  @spec create(
    configuration :: t()
  ) :: {:ok, configuration :: t()} | {:error, Ecto.Changeset.t()}
  def create(%Configuration{} = configuration), do: configuration |> create_changeset() |> Repo.insert()

  @doc """
  Gets a `Configuration` from the database by `name`
  """
  @spec by_name(name :: String.t()) :: t() | nil
  def by_name(name) when is_binary(name), do: Repo.get_by(Configuration, name: name)

  @doc """
  Gets default frontend `Configuration` from the database
  """
  @spec get_default() :: t() | nil
  def get_default(), do: by_name("default")

  @doc """
  Inserts a default `Configuration` into the database given `config_map`
  """
  @spec set_default(
    config_map :: map()
  ) :: {:ok, configuration :: t()} | {:error, Ecto.Changeset.t()}
  def set_default(config_map) when is_map(config_map) do
    %Configuration{}
    |> create_changeset(%{ name: "default", config: config_map })
    |> Repo.insert()
  end

end
