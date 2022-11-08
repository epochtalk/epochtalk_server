defmodule EpochtalkServerWeb.MentionViewTest do
  use EpochtalkServerWeb.ConnCase, async: true
  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View
  alias EpochtalkServerWeb.MentionView
  alias EpochtalkServer.Models.{User, Mention, Thread, Post, Board}

  # this was too long to be a doctest, we still need to test with Sandbox db connection
  test "renders page.json [extended: false]" do
    mentions = [%Mention{
     id: 5,
     thread_id: 2,
     thread: %Thread{
       id: 2,
       board_id: 1,
       board: %Board{
         id: 1,
         name: "General Discussion",
         slug: "general-discussion",
         description: "Discuss things generally",
         post_count: 0,
         thread_count: 2,
         viewable_by: nil,
         postable_by: nil,
         right_to_left: false,
         created_at: nil,
         imported_at: nil,
         updated_at: nil,
         meta: nil,
         category: nil
       },
       locked: false,
       sticky: false,
       slug: "test-thread",
       moderated: false,
       post_count: 2,
       created_at: ~N[2022-11-01 23:36:51],
       imported_at: nil,
       updated_at: ~N[2022-11-01 23:36:51],
       posts: nil
     },
     post_id: 5,
     post: %Post{
       id: 5,
       thread_id: 2,
       thread: nil,
       user_id: 80,
       user: nil,
       locked: false,
       deleted: false,
       position: 1,
       content: %{"body" => "test post", "title" => "RE: test thread"},
       metadata: nil,
       created_at: ~N[2022-11-01 23:38:57],
       updated_at: ~N[2022-11-01 23:38:57],
       imported_at: nil
     },
     mentioner_id: 80,
     mentioner: %User{
       id: 80,
       email: "test@example.com",
       username: "test",
       passhash: "******",
       confirmation_token: nil,
       reset_token: nil,
       reset_expiration: nil,
       created_at: nil,
       imported_at: nil,
       updated_at: nil,
       deleted: false,
       malicious_score: 1.0416,
       smf_member: nil,
       preferences: nil,
       profile: nil,
       ban_info: nil,
       roles: nil,
       moderating: nil
     },
     mentionee_id: 1,
     mentionee: nil,
     created_at: ~N[2022-11-01 23:39:14],
     viewed: false,
     notification_id: 5
   }]
   pagination_data = %{page: 1, limit: 1, next: true, prev: false}
   result = %{
    data: [%{
      created_at: ~N[2022-11-01 23:39:14],
      id: 5,
      mentioner: "test",
      mentioner_avatar: nil,
      notification_id: 5,
      post_id: 5,
      post_start: 1,
      thread_id: 2,
      thread_slug: "test-thread",
      title: "RE: test thread",
      viewed: false
    }],
    limit: 1,
    next: true,
    page: 1,
    prev: false
  }
   assert result == render(MentionView, "page.json", %{mentions: mentions, pagination_data: pagination_data, extended: false})
  end

  test "renders page.json [extended: true]" do
    mentions = [%Mention{
     id: 5,
     thread_id: 2,
     thread: %Thread{
       id: 2,
       board_id: 1,
       board: %Board{
         id: 1,
         name: "General Discussion",
         slug: "general-discussion",
         description: "Discuss things generally",
         post_count: 0,
         thread_count: 2,
         viewable_by: nil,
         postable_by: nil,
         right_to_left: false,
         created_at: nil,
         imported_at: nil,
         updated_at: nil,
         meta: nil,
         category: nil
       },
       locked: false,
       sticky: false,
       slug: "test-thread",
       moderated: false,
       post_count: 2,
       created_at: ~N[2022-11-01 23:36:51],
       imported_at: nil,
       updated_at: ~N[2022-11-01 23:36:51],
       posts: nil
     },
     post_id: 5,
     post: %Post{
       id: 5,
       thread_id: 2,
       thread: nil,
       user_id: 80,
       user: nil,
       locked: false,
       deleted: false,
       position: 1,
       content: %{"body" => "test post", "title" => "RE: test thread"},
       metadata: nil,
       created_at: ~N[2022-11-01 23:38:57],
       updated_at: ~N[2022-11-01 23:38:57],
       imported_at: nil
     },
     mentioner_id: 80,
     mentioner: %User{
       id: 80,
       email: "test@example.com",
       username: "test",
       passhash: "******",
       confirmation_token: nil,
       reset_token: nil,
       reset_expiration: nil,
       created_at: nil,
       imported_at: nil,
       updated_at: nil,
       deleted: false,
       malicious_score: 1.0416,
       smf_member: nil,
       preferences: nil,
       profile: nil,
       ban_info: nil,
       roles: nil,
       moderating: nil
     },
     mentionee_id: 1,
     mentionee: nil,
     created_at: ~N[2022-11-01 23:39:14],
     viewed: false,
     notification_id: 5
   }]
   pagination_data = %{page: 2, limit: 1, next: true, prev: true}
   result = %{
    data: [%{
      created_at: ~N[2022-11-01 23:39:14],
      id: 5,
      mentioner: "test",
      mentioner_avatar: nil,
      notification_id: 5,
      post_id: 5,
      post_start: 1,
      thread_id: 2,
      thread_slug: "test-thread",
      title: "RE: test thread",
      viewed: false,
      board_id: 1,
      board_name: "General Discussion",
      body_html: "test post"
    }],
    limit: 1,
    next: true,
    page: 2,
    prev: true,
    extended: true
  }
   assert result == render(MentionView, "page.json", %{mentions: mentions, pagination_data: pagination_data, extended: true})
  end
end
