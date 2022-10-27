defmodule EpochtalkServerWeb.UserViewTest do
  use EpochtalkServerWeb.ConnCase, async: true
  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View
  alias EpochtalkServerWeb.UserView
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Preference
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.BoardModerator

  # Specify that we want to use doctests:
  doctest EpochtalkServerWeb.UserView

  # this was too long to be a doctest, we still need to test with Sandbox db connection
  test "renders user.json" do
    user = %User{
      id: 1,
      email: "test@example.com",
      username: "Test",
      passhash: "************",
      confirmation_token: nil,
      reset_token: nil,
      reset_expiration: nil,
      created_at: nil,
      imported_at: nil,
      updated_at: nil,
      deleted: false,
      malicious_score: 1.0416,
      smf_member: nil,
      preferences: %Preference{
        user_id: 1,
        posts_per_page: 25,
        threads_per_page: 25,
        collapsed_categories: %{"cats" => []},
        ignored_boards: %{"boards" => []},
        timezone_offset: "",
        notify_replied_threads: true,
        ignore_newbies: true,
        patroller_view: false,
        email_mentions: true,
        email_messages: true
      },
      profile: %Profile{
        id: 1,
        user_id: 1,
        avatar: "",
        position: nil,
        signature: "-my signature",
        raw_signature: nil,
        post_count: 1,
        fields: nil,
        last_active: nil
      },
      ban_info: %Ban{
        id: 1,
        user_id: 1,
        expiration: ~N[2022-10-01 06:21:52],
        created_at: ~N[2022-09-30 00:09:06],
        updated_at: ~N[2022-10-01 06:21:52]
      },
      roles: [
        %Role{
          id: 5,
          name: "User",
          description: "Standard account with access to create threads and post",
          lookup: "user",
          priority: 4,
          highlight_color: nil,
          permissions: %{
            "ads" => %{
              "analyticsView" => %{"allow" => true},
              "roundInfo" => %{"allow" => true},
              "view" => %{"allow" => true}
            },
            "boards" => %{
              "allCategories" => %{"allow" => true},
              "find" => %{"allow" => true}
            },
            "conversations" => %{
              "create" => %{"allow" => true},
              "delete" => %{"allow" => true},
              "messages" => %{"allow" => true}
            },
            "invitations" => %{"invite" => %{"allow" => true}},
            "mentions" => %{
              "create" => %{"allow" => true},
              "delete" => %{"allow" => true},
              "page" => %{"allow" => true}
            },
            "messages" => %{
              "create" => %{"allow" => true},
              "delete" => %{"allow" => true, "bypass" => %{"owner" => true}},
              "latest" => %{"allow" => true}
            },
            "motd" => %{"get" => %{"allow" => true}},
            "notifications" => %{
              "counts" => %{"allow" => true},
              "dismiss" => %{"allow" => true}
            },
            "portal" => %{"view" => %{"allow" => true}},
              "posts" => %{
               "byThread" => %{
                 "allow" => true,
                 "bypass" => %{"viewDeletedPosts" => %{"selfMod" => true}}
               },
               "create" => %{"allow" => true},
               "delete" => %{
                 "allow" => true,
                 "bypass" => %{
                   "locked" => %{"selfMod" => true},
                   "owner" => %{"selfMod" => true}
                 }
               },
               "find" => %{"allow" => true},
               "lock" => %{
                 "allow" => true,
                 "bypass" => %{"lock" => %{"selfMod" => true}}
               },
               "pageByUser" => %{"allow" => true},
               "search" => %{"allow" => true},
               "update" => %{"allow" => true}
            },
            "reports" => %{
              "createMessageReport" => %{"allow" => true},
              "createPostReport" => %{"allow" => true},
              "createUserReport" => %{"allow" => true}
            },
            "threads" => %{
              "byBoard" => %{"allow" => true},
              "create" => %{"allow" => true},
              "createPoll" => %{"allow" => true},
              "editPoll" => %{"allow" => true},
              "lockPoll" => %{"allow" => true},
              "moderated" => %{"allow" => true},
              "posted" => %{"allow" => true},
              "removeVote" => %{"allow" => true},
              "title" => %{"allow" => true},
              "viewed" => %{"allow" => true},
              "vote" => %{"allow" => true}
            },
            "userTrust" => %{"addTrustFeedback" => %{"allow" => true}},
            "users" => %{
              "deactivate" => %{"allow" => true},
              "find" => %{"allow" => true},
              "lookup" => %{"allow" => true},
              "pagePublic" => %{"allow" => true},
              "reactivate" => %{"allow" => true},
              "update" => %{"allow" => true}
            },
            "watchlist" => %{
              "edit" => %{"allow" => true},
              "pageBoards" => %{"allow" => true},
              "pageThreads" => %{"allow" => true},
              "unread" => %{"allow" => true},
              "unwatchBoard" => %{"allow" => true},
              "unwatchThread" => %{"allow" => true},
              "watchBoard" => %{"allow" => true},
              "watchThread" => %{"allow" => true}
            }
          },
          priority_restrictions: nil,
          created_at: ~N[2022-08-30 00:45:30],
          updated_at: ~N[2022-08-30 00:45:30]
        }
      ],
      moderating: [
        %BoardModerator{
          user_id: 1,
          board_id: 1,
        },
        %BoardModerator{
          user_id: 1,
          board_id: 2,
        }
      ]
    }
    token = "********"
    assert render(UserView, "user.json", %{user: user, token: token}) == %{
      avatar: "",
      ban_expiration: ~N[2022-10-01 06:21:52],
      id: 1,
      malicious_score: 1.0416,
      moderating: [1, 2],
      permissions: %{
        :highlight_color => nil,
        :priority => 4,
        :priority_restrictions => nil,
        "ads" => %{
          "analyticsView" => %{"allow" => true},
          "roundInfo" => %{"allow" => true},
          "view" => %{"allow" => true}
        },
        "boards" => %{
          "allCategories" => %{"allow" => true},
          "find" => %{"allow" => true}
        },
        "conversations" => %{
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true},
          "messages" => %{"allow" => true}
        },
        "invitations" => %{"invite" => %{"allow" => true}},
        "mentions" => %{
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true},
          "page" => %{"allow" => true}
        },
        "messages" => %{
          "create" => %{"allow" => true},
          "delete" => %{"allow" => true, "bypass" => %{"owner" => true}},
          "latest" => %{"allow" => true}
        },
        "motd" => %{"get" => %{"allow" => true}},
        "notifications" => %{
          "counts" => %{"allow" => true},
          "dismiss" => %{"allow" => true}
        },
        "portal" => %{"view" => %{"allow" => true}},
        "posts" => %{
          "byThread" => %{
            "allow" => true,
            "bypass" => %{"viewDeletedPosts" => %{"selfMod" => true}}
          },
          "create" => %{"allow" => true},
          "delete" => %{
            "allow" => true,
            "bypass" => %{
              "locked" => %{"selfMod" => true},
              "owner" => %{"selfMod" => true}
            }
          },
          "find" => %{"allow" => true},
          "lock" => %{
            "allow" => true,
            "bypass" => %{"lock" => %{"selfMod" => true}}
          },
          "pageByUser" => %{"allow" => true},
          "search" => %{"allow" => true},
          "update" => %{"allow" => true}
        },
        "reports" => %{
          "createMessageReport" => %{"allow" => true},
          "createPostReport" => %{"allow" => true},
          "createUserReport" => %{"allow" => true}
        },
        "threads" => %{
          "byBoard" => %{"allow" => true},
          "create" => %{"allow" => true},
          "createPoll" => %{"allow" => true},
          "editPoll" => %{"allow" => true},
          "lockPoll" => %{"allow" => true},
          "moderated" => %{"allow" => true},
          "posted" => %{"allow" => true},
          "removeVote" => %{"allow" => true},
          "title" => %{"allow" => true},
          "viewed" => %{"allow" => true},
          "vote" => %{"allow" => true}
        },
        "userTrust" => %{"addTrustFeedback" => %{"allow" => true}},
        "users" => %{
          "deactivate" => %{"allow" => true},
          "find" => %{"allow" => true},
          "lookup" => %{"allow" => true},
          "pagePublic" => %{"allow" => true},
          "reactivate" => %{"allow" => true},
          "update" => %{"allow" => true}
        },
        "watchlist" => %{
          "edit" => %{"allow" => true},
          "pageBoards" => %{"allow" => true},
          "pageThreads" => %{"allow" => true},
          "unread" => %{"allow" => true},
          "unwatchBoard" => %{"allow" => true},
          "unwatchThread" => %{"allow" => true},
          "watchBoard" => %{"allow" => true},
          "watchThread" => %{"allow" => true}
        }
      },
      roles: ["user"],
      token: "********",
      username: "Test"
    }
  end
end
