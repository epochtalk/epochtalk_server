defmodule EpochtalkServer.Models.PriorityRestriction do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.PriorityRestriction

  schema "priority_restrictions" do
    belongs_to :role, Role, foreign_key: :role_lookup, type: :string, primary_key: true
    field :restrictions, {:array, :integer}
  end
  def changeset(priority_restrictions, attrs \\ %{}) do
    priority_restrictions
    |> cast(attrs, [:role_lookup, :restrictions])
    |> validate_required([:role_lookup, :restrictions])
  end
  def by_lookup(role_lookup)
      when is_binary(role_lookup) do
    Repo.get_by(PriorityRestriction, role_lookup: role_lookup)
  end
  def all() do
    Repo.all(PriorityRestriction)
  end
end
