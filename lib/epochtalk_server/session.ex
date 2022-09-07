defmodule EpochtalkServer.Session do
  def save(db_user) do
    # replace db_user role with role lookups
    # |> Map.put(:role, Enum.map(db_user.roles, &(&1.lookup))
    # actually, just assume role lookups are there

    # set default role if necessary
    roles = db_user.roles
    |> List.length
    |> case do
      0 -> ['user']
      _ -> db_user.roles
    end
    db_user = Map.put(db_user, :roles, roles)

    # save username, avatar to redis hash under "user:{userId}"
    user_key = "user:#{db_user.id}"
    case db_user.avatar do
      "" -> Redix.command(:redix, ["HSET", user_key, "username", db_user.username])
      # set avatar if it's available
      _ -> Redix.command(:redix, ["HSET", user_key, "username", db_user.username, "avatar", db_user.avatar])
    end
  end
  def update_roles do

  end
  def update_moderating do

  end
  def update_user_info do

  end
  def update_ban_info do

  end
end
