defmodule EpochtalkServer.Models.Role do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser

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

  def set_permissions(id, permissions) do
    Role
    |> Repo.get(id)
    |> change(%{ permissions: permissions })
    |> Repo.update
  end

  def get_banned_role_id(), do: Repo.one(from(r in Role, select: r.id, where: r.lookup == "banned"))
  def get_newbie_role_id(), do: Repo.one(from(r in Role, select: r.id, where: r.lookup == "newbie"))
  def by_user_id(user_id) do
    query = from ru in RoleUser,
      join: r in Role,
      where: ru.user_id == ^user_id and r.id == ru.role_id,
      select: r,
      order_by: [asc: r.priority]
    case Repo.all(query) do
      [] -> [get_default()]
      result -> result
    end
  end
  defp get_default(), do: by_lookup("user")
end
