defmodule EpochtalkServer.Models.Role do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Role

  schema "roles" do
    field :name, :string
    field :description, :string
    field :lookup, :string
    field :priority, :integer
    field :highlight_color, :string

    field :permissions, :map
    field :priority_restrictions, {:array, :integer}

    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  def changeset(role, attrs \\ %{}) do
    role
    |> cast(attrs, [:name, :description, :lookup, :priority, :permissions])
    |> validate_required([:name, :description, :lookup, :priority, :permissions])
  end
  def all, do: from(r in Role, order_by: r.id) |> Repo.all
  def by_lookup(lookup), do: Repo.get_by(Role, lookup: lookup)
  def insert([]), do: {:error, "Role list is empty"}
  def insert(%Role{} = role), do: Repo.insert(role)
  def insert([%{}|_] = roles), do: Repo.insert_all(Role, roles)

  def set_priority_restrictions_by_lookup({lookup, priority_restrictions}) do
    # only insert priority restrictions if they have not been set already
    from(r in Role, where: r.lookup == ^lookup and is_nil(r.priority_restrictions))
    |> Repo.update_all(set: [priority_restrictions: priority_restrictions])
  end

  def set_permissions(id, permissions) do
    Role
    |> Repo.get(id)
    |> change(%{ permissions: permissions })
    |> Repo.update
  end
end
