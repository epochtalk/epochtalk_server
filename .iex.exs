IEx.configure(inspect: [charlists: :as_lists])
IEx.configure(inspect: [limit: :infinity])

alias EpochtalkServer.Repo

alias EpochtalkServer.Models.{
  Ban,
  BannedAddress,
  Board,
  BoardMapping,
  BoardModerator,
  Category,
  Configuration,
  Invitation,
  MetadataBoard,
  Notification,
  Permission,
  Preference,
  Profile,
  Role,
  RolePermission,
  RoleUser,
  User
}

reload = fn() -> r Enum.map(__ENV__.aliases, fn {_, module} -> module end) end
