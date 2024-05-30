IEx.configure(inspect: [charlists: :as_lists])
IEx.configure(inspect: [limit: :infinity])

alias EpochtalkServer.Repo

alias EpochtalkServer.Models.{
  AutoModeration,
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
  MentionIgnored,
  MetadataBoard,
  MetadataThread,
  MetricRankMap,
  Notification,
  Permission,
  Post,
  PostDraft,
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
  ThreadSubscription,
  Trust,
  TrustBoard,
  TrustFeedback,
  TrustMaxDepth,
  User,
  UserActivity,
  UserIgnored,
  UserThreadView,
  WatchBoard,
  WatchThread
}

reload = fn -> r(Enum.map(__ENV__.aliases, fn {_, module} -> module end)) end
