IEx.configure(inspect: [charlists: :as_lists])
IEx.configure(inspect: [limit: :infinity])

alias EpochtalkServer.Repo

alias EpochtalkServer.Models.{
  Ban,
  BannedAddress,
  Board,
  BoardBan,
  BoardMapping,
  BoardModerator,
  Category,
  Configuration,
  Invitation,
  Mention,
  MetadataBoard,
  MetadataThread,
  MetricRankMap,
  Notification,
  Permission,
  Post,
  Poll,
  PollAnswer,
  PollResponse,
  Preference,
  Profile,
  Rank,
  Role,
  RolePermission,
  RoleUser,
  Thread,
  User
}

reload = fn -> r(Enum.map(__ENV__.aliases, fn {_, module} -> module end)) end
