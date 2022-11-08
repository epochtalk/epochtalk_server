defmodule EpochtalkServer.Models.Configuration do
  use Ecto.Schema
  import Logger, only: [debug: 1]
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
  ) :: Ecto.Changeset.t()
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
    |> Repo.insert(returning: [:config])
  end

  ## === External Helper Functions ===

  @doc """
  Warms `:epochtalk_server[:frontend_config]` config variable using `Configuration` stored in database,
  if present. If there is no `Configuration` in the database, the default value is taken
  from `:epochtalk_server[:frontend_config]` and inserted into the database as the default
  `Configuration`. Run as a Task on application startup.
  """
  @spec warm_frontend_config() :: :ok
  def warm_frontend_config() do
    frontend_config = case Configuration.get_default() do
      nil -> # no configurations in database
        debug("Frontend Configurations not found, setting defaults in Database")
        frontend_config = Application.get_env(:epochtalk_server, :frontend_config)
        case Configuration.set_default(frontend_config) do
          {:ok, configuration} -> configuration.config
          {:error, _} -> raise("There was an issue with :epochtalk_server[:frontend_configs], please check config/config.exs")
        end
      configuration -> # configuration found in database
        debug("Loading Frontend Configurations from Database")
        configuration.config
    end
    Application.put_env(:epochtalk_server, :frontend_config, frontend_config)
    set_git_revision()
    debug "Frontend Configuration:\n"
      <> inspect(
          Application.get_env(:epochtalk_server, :frontend_config),
          pretty: true,
          syntax_colors: IO.ANSI.syntax_colors
        )
    :ok
  end

  ## === Private Helper Functions ===

  defp set_git_revision() do
    # tag
    {tag, _} = System.cmd("git", ["tag", "--points-at", "HEAD", "v[0-9]*"])
    [tag | _] = tag |> String.split("\n")

    # revision
    {hash, _} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    [hash | _] = hash |> String.split("\n")

    # TODO(boka): directory release version

    # tag takes precidence over revision
    revision = if tag == "", do: hash, else: tag

    frontend_config = Application.get_env(:epochtalk_server, :frontend_config)
      |> Map.put("revision", revision)
    Application.put_env(:epochtalk_server, :frontend_config, frontend_config)
  end
end
