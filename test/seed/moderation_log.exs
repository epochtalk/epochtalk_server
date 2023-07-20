import Test.Support.Factory
alias EpochtalkServer.Models.ModerationLog
alias EpochtalkServer.Models.User

board = insert(:board, name: "General Discussion", slug: "general-discussion")
test_user_username = "test"
{:ok, user} = User.by_username(test_user_username)
thread = build(:thread, board: board, user: user, title: "test", slug: "test_slug")
thread_id = thread.post.thread_id

logs = [
  %{
    mod: %{
      username: "one.adminBoards.updateCategories",
      id: 1,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/boards/all",
      api_method: "post",
      type: "adminBoards.updateCategories",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "two.adminBoards.updateCategories",
      id: 2,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/boards/all",
      api_method: "post",
      type: "adminBoards.updateCategories",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "one.adminModerators.add",
      id: 3,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/admin/moderators",
      api_method: "post",
      type: "adminModerators.add",
      obj: %{usernames: [user.username], board_id: board.id}
    }
  },
  %{
    mod: %{
      username: "two.adminModerators.add",
      id: 4,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/boards/all",
      api_method: "post",
      type: "adminBoards.updateCategories",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "three.adminModerators.add",
      id: 5,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/admin/moderators",
      api_method: "post",
      type: "adminModerators.add",
      obj: %{usernames: [user.username], board_id: board.id}
    }
  },
  %{
    mod: %{
      username: "adminModerators.remove",
      id: 6,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/admin/moderators",
      api_method: "delete",
      type: "adminModerators.remove",
      obj: %{usernames: [user.username], board_id: board.id}
    }
  },
  %{
    mod: %{
      username: "reports.updateMessageReport",
      id: 7,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/updateMessageReport",
      api_method: "post",
      type: "reports.updateMessageReport",
      obj: %{status: "test", id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.createMessageReportNote",
      id: 8,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/createMessageReportNote",
      api_method: "post",
      type: "reports.createMessageReportNote",
      obj: %{report_id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.updateMessageReportNote",
      id: 9,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/updateMessageReportNote",
      api_method: "post",
      type: "reports.updateMessageReportNote",
      obj: %{report_id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.updatePostReport",
      id: 10,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/updatePostReport",
      api_method: "post",
      type: "reports.updatePostReport",
      obj: %{status: "test", id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.createPostReportNote",
      id: 11,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/createPostReportNote",
      api_method: "post",
      type: "reports.createPostReportNote",
      obj: %{report_id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.updatePostReportNote",
      id: 12,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/updatePostReportNote",
      api_method: "post",
      type: "reports.updatePostReportNote",
      obj: %{report_id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.updateUserReport",
      id: 13,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/updateUserReport",
      api_method: "post",
      type: "reports.updateUserReport",
      obj: %{status: "test", id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.createUserReportNote",
      id: 14,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/createUserReportNote",
      api_method: "post",
      type: "reports.createUserReportNote",
      obj: %{report_id: 1}
    }
  },
  %{
    mod: %{
      username: "reports.updateUserReportNote",
      id: 15,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/reports/updateUserReportNote",
      api_method: "post",
      type: "reports.updateUserReportNote",
      obj: %{report_id: 1}
    }
  },
  %{
    mod: %{
      username: "adminRoles.add",
      id: 16,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/roles/add",
      api_method: "post",
      type: "adminRoles.add",
      obj: %{name: "test", id: 1}
    }
  },
  %{
    mod: %{
      username: "adminRoles.remove",
      id: 17,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/roles/remove",
      api_method: "delete",
      type: "adminRoles.remove",
      obj: %{name: "test"}
    }
  },
  %{
    mod: %{
      username: "adminRoles.update",
      id: 18,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/roles/update",
      api_method: "post",
      type: "adminRoles.update",
      obj: %{name: "test", id: 1}
    }
  },
  %{
    mod: %{
      username: "adminRoles.reprioritize",
      id: 19,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/roles/reprioritize",
      api_method: "get",
      type: "adminRoles.reprioritize",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "adminSettings.update",
      id: 20,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/settings/update",
      api_method: "post",
      type: "adminSettings.update",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "adminSettings.addToBlacklist",
      id: 21,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/settings/addToBlacklist",
      api_method: "post",
      type: "adminSettings.addToBlacklist",
      obj: %{note: "test_note"}
    }
  },
  %{
    mod: %{
      username: "adminSettings.updateBlacklist",
      id: 22,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/settings/updateBlacklist",
      api_method: "post",
      type: "adminSettings.updateBlacklist",
      obj: %{note: "test_note"}
    }
  },
  %{
    mod: %{
      username: "adminSettings.deleteFromBlacklist",
      id: 23,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/settings/deleteFromBlacklist",
      api_method: "delete",
      type: "adminSettings.deleteFromBlacklist",
      obj: %{note: "test_note"}
    }
  },
  %{
    mod: %{
      username: "adminSettings.setTheme",
      id: 24,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/settings/setTheme",
      api_method: "post",
      type: "adminSettings.setTheme",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "adminSettings.resetTheme",
      id: 25,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/settings/resetTheme",
      api_method: "post",
      type: "adminSettings.resetTheme",
      obj: %{}
    }
  },
  %{
    mod: %{
      username: "adminUsers.addRoles",
      id: 26,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/users/addRoles",
      api_method: "post",
      type: "adminUsers.addRoles",
      obj: %{usernames: [user.username], role_id: 1}
    }
  },
  %{
    mod: %{
      username: "adminUsers.removeRoles",
      id: 27,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/users/removeRoles",
      api_method: "delete",
      type: "adminUsers.removeRoles",
      obj: %{role_id: 1, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "userNotes.create",
      id: 28,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/userNotes/create",
      api_method: "post",
      type: "userNotes.create",
      obj: %{user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "userNotes.update",
      id: 29,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/userNotes/update",
      api_method: "post",
      type: "userNotes.update",
      obj: %{user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "userNotes.delete",
      id: 30,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/userNotes/delete",
      api_method: "delete",
      type: "userNotes.delete",
      obj: %{user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "bans.addAddresses",
      id: 31,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/addAddresses",
      api_method: "post",
      type: "bans.addAddresses",
      obj: %{addresses: [%{hostname: nil, ip: "127.0.0.1"}]}
    }
  },
  %{
    mod: %{
      username: "bans.editAddress",
      id: 32,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/editAddress",
      api_method: "post",
      type: "bans.editAddress",
      obj: %{hostname: nil, ip: "127.0.0.1", weight: "99", decay: nil}
    }
  },
  %{
    mod: %{
      username: "bans.deleteAddress",
      id: 33,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/deleteAddress",
      api_method: "delete",
      type: "bans.deleteAddress",
      obj: %{hostname: nil, ip: "127.0.0.1"}
    }
  },
  %{
    mod: %{
      username: "bans.ban",
      id: 34,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/ban",
      api_method: "post",
      type: "bans.ban",
      obj: %{expiration: ~N[2030-12-31 00:00:00.000], user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "bans.unban",
      id: 35,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/unban",
      api_method: "post",
      type: "bans.unban",
      obj: %{user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "bans.banFromBoards",
      id: 36,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/banFromBoards",
      api_method: "post",
      type: "bans.banFromBoards",
      obj: %{board_ids: [1], user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "bans.unbanFromBoards",
      id: 37,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/bans/unbanFromBoards",
      api_method: "post",
      type: "bans.unbanFromBoards",
      obj: %{board_ids: [1], user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "boards.create",
      id: 38,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/boards/create",
      api_method: "post",
      type: "boards.create",
      obj: %{boards: [%{name: "test_board"}]}
    }
  },
  %{
    mod: %{
      username: "boards.update",
      id: 39,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/boards/update",
      api_method: "post",
      type: "boards.update",
      obj: %{boards: [%{name: "test_board"}]}
    }
  },
  %{
    mod: %{
      username: "boards.delete",
      id: 40,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/boards/delete",
      api_method: "delete",
      type: "boards.delete",
      obj: %{names: "test_board"}
    }
  },
  %{
    mod: %{
      username: "threads.title",
      id: 41,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/title",
      api_method: "post",
      type: "threads.title",
      obj: %{thread_id: thread_id, user_id: user.id, title: "new_title"}
    }
  },
  %{
    mod: %{
      username: "threads.lock",
      id: 42,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/lock",
      api_method: "post",
      type: "threads.lock",
      obj: %{locked: true, user_id: user.id, thread_id: thread_id}
    }
  },
  %{
    mod: %{
      username: "threads.sticky",
      id: 43,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/sticky",
      api_method: "post",
      type: "threads.sticky",
      obj: %{stickied: true, thread_id: thread_id, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "threads.move",
      id: 44,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/move",
      api_method: "post",
      type: "threads.move",
      obj: %{
        title: "new_title",
        thread_id: thread_id,
        user_id: user.id,
        old_board_name: "old_board",
        new_board_id: board.id
      }
    }
  },
  %{
    mod: %{
      username: "threads.purge",
      id: 45,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/purge",
      api_method: "post",
      type: "threads.purge",
      obj: %{title: "title", user_id: user.id, old_board_name: "old_board", board_id: board.id}
    }
  },
  %{
    mod: %{
      username: "threads.editPoll",
      id: 46,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/editPoll",
      api_method: "post",
      type: "threads.editPoll",
      obj: %{thread_id: thread_id, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "threads.createPoll",
      id: 47,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/createPoll",
      api_method: "post",
      type: "threads.createPoll",
      obj: %{thread_id: thread_id, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "threads.lockPoll",
      id: 48,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/threads/lockPoll",
      api_method: "post",
      type: "threads.lockPoll",
      obj: %{locked: false, thread_id: thread_id, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "posts.update",
      id: 49,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/posts/update",
      api_method: "post",
      type: "posts.update",
      obj: %{id: 1, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "posts.delete",
      id: 50,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/posts/delete",
      api_method: "delete",
      type: "posts.delete",
      obj: %{id: 1, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "posts.undelete",
      id: 51,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/posts/undelete",
      api_method: "post",
      type: "posts.undelete",
      obj: %{id: 1, user_id: user.id}
    }
  },
  %{
    mod: %{
      username: "posts.purge",
      id: 52,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/posts/purge",
      api_method: "post",
      type: "posts.purge",
      obj: %{user_id: user.id, thread_id: thread_id}
    }
  },
  %{
    mod: %{
      username: "users.update",
      id: 53,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/users/update",
      api_method: "post",
      type: "users.update",
      obj: %{username: user.username}
    }
  },
  %{
    mod: %{
      username: "users.deactivate",
      id: 54,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/users/deactivate",
      api_method: "post",
      type: "users.deactivate",
      obj: %{id: user.id}
    }
  },
  %{
    mod: %{
      username: "users.reactivate",
      id: 55,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/users/reactivate",
      api_method: "post",
      type: "users.reactivate",
      obj: %{id: user.id}
    }
  },
  %{
    mod: %{
      username: "users.delete",
      id: 56,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/users/delete",
      api_method: "delete",
      type: "users.delete",
      obj: %{username: user.username}
    }
  },
  %{
    mod: %{
      username: "conversations.delete",
      id: 57,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/conversations/delete",
      api_method: "delete",
      type: "conversations.delete",
      obj: %{
        sender_id: 2,
        receiver_ids: [1]
      }
    }
  },
  %{
    mod: %{
      username: "messages.delete",
      id: 58,
      ip: "127.0.0.1"
    },
    action: %{
      api_url: "/api/messages/delete",
      api_method: "delete",
      type: "messages.delete",
      obj: %{
        sender_id: 2,
        receiver_ids: [1]
      }
    }
  }
]

try do
  logs
  |> Enum.with_index()
  |> Enum.filter(fn {log, index} ->
    ModerationLog.create(log)
    |> case do
      {:ok, _} ->
        if index + 1 == length(logs) do
          IO.puts("Successfully Seeded Moderation Log Entries")
        end

      {:error, error} ->
        IO.puts("Error Seeding Moderation Log Entry #{index + 1}")
        IO.inspect(error)
    end
  end)
rescue
  Postgrex.Error -> IO.puts("Error seeding Moderation Log. Moderation Log may already be seeded.")
end
