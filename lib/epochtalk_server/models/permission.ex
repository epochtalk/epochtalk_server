defmodule EpochtalkServer.Models.Permission do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Permission
  @moduledoc """
  `Permission` model, for performing actions relating to `Role` permissions, used for seeding
  """

  @type t :: %__MODULE__{
    path: String.t() | nil
  }
  @primary_key false
  schema "permissions" do
    field :path, :string
  end

  ## === Changesets Functions ===

  @doc """
  Creates a generic changeset for `Permission` model
  """
  @spec changeset(permission :: t(), attrs :: map() | nil) :: %Ecto.Changeset{}
  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:path])
    |> validate_required([:path])
  end

  ## === Database Functions ===

  @doc """
  Returns every `Permission` record in the database
  """
  @spec all() :: [t()] | []
  def all(), do: Repo.all(Permission)

  @doc """
  Returns a specific `Permission` provided it's path
  """
  @spec by_path(path :: String.t()) :: t() | nil
  def by_path(path) when is_binary(path), do: Repo.get_by(Permission, path: path)
end
