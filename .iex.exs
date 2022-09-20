alias EpochtalkServer.Repo

alias EpochtalkServer.Models.Ban
alias EpochtalkServer.Models.BannedAddress
alias EpochtalkServer.Models.Board
alias EpochtalkServer.Models.BoardMapping
alias EpochtalkServer.Models.BoardModerator
alias EpochtalkServer.Models.Category
alias EpochtalkServer.Models.Invitation
alias EpochtalkServer.Models.MetadataBoard
alias EpochtalkServer.Models.Permission
alias EpochtalkServer.Models.Preference
alias EpochtalkServer.Models.Profile
alias EpochtalkServer.Models.Role
alias EpochtalkServer.Models.RolePermission
alias EpochtalkServer.Models.RoleUser
alias EpochtalkServer.Models.User

reload = fn() ->
  r [
    Ban,
    BannedAddress,
    Board,
    BoardMapping,
    BoardModerator,
    Category,
    Invitation,
    MetadataBoard,
    Permission,
    Preference,
    Profile,
    Role,
    RolePermission,
    RoleUser,
    User
  ]
end
