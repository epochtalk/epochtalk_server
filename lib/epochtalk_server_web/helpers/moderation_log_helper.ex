defmodule EpochtalkServerWeb.Helpers.ModerationLogHelper do
  @moduledoc """
  Helper for obtaining display data for ModerationLog entries
  """
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.User

  def get_display_data(action_type) when action_type == "adminBoards.updateCategories" do
    %{
      get_display_text: fn _ -> "updated boards and categories" end,
      get_display_url: fn _ -> "admin-management.boards" end
    }
  end

  def get_display_data(action_type) when action_type == "adminModerators.add" do
    %{
      get_display_text: fn data ->
        "added user(s) '#{Enum.join(data.usernames, ", ")}' to list of moderators for board '#{data.board_name}'"
      end,
      get_display_url: fn data -> "threads.data({ boardSlug: '#{data.board_slug}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(Board, id: data.board_id) do
            nil ->
              data

            board ->
              data
              |> Map.put(:board_slug, board.slug)
              |> Map.put(:board_name, board.name)
              |> replace_key_value(:board_moderators, board, :moderators)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "adminModerators.remove" do
    %{
      get_display_text: fn data ->
        "removed user(s) '#{Enum.join(data.usernames, ", ")}' from list of moderators for board '#{data.board_name}'"
      end,
      get_display_url: fn data -> "threads.data({ boardSlug: '#{data.board_slug}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(Board, id: data.board_id) do
            nil ->
              data

            board ->
              data
              |> Map.put(:board_slug, board.slug)
              |> Map.put(:board_name, board.name)
              |> replace_key_value(:board_moderators, board, :moderators)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "reports.updateMessageReport" do
    %{
      get_display_text: fn data ->
        "updated the status of message report to '#{data.status}'"
      end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.createMessageReportNote" do
    %{
      get_display_text: fn _ -> "created a note on a message report" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.report_id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.updateMessageReportNote" do
    %{
      get_display_text: fn _ -> "edited their note on a message report" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.report_id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.updatePostReport" do
    %{
      get_display_text: fn data -> "updated the status of post report to '#{data.status}'" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.createPostReportNote" do
    %{
      get_display_text: fn _ -> "created a note on a post report" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.report_id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.updatePostReportNote" do
    %{
      get_display_text: fn _ -> "edited their note on a post report" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.report_id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.updateUserReport" do
    %{
      get_display_text: fn data -> "updated the status of user report to '#{data.status}'" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.createUserReportNote" do
    %{
      get_display_text: fn _ -> "created a note on a user report" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.report_id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "reports.updateUserReportNote" do
    %{
      get_display_text: fn _ -> "edited their note on a user report" end,
      get_display_url: fn data -> "^.messages({ reportId: '#{data.report_id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "adminRoles.add" do
    %{
      get_display_text: fn data -> "created a new role named '#{data.name}'" end,
      get_display_url: fn data -> "admin-management.roles({ roleId: '#{data.id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "adminRoles.remove" do
    %{
      get_display_text: fn data -> "removed the role named '#{data.name}'" end,
      get_display_url: fn _ -> "admin-management.roles" end
    }
  end

  def get_display_data(action_type) when action_type == "adminRoles.update" do
    %{
      get_display_text: fn data -> "updated the role named '#{data.name}'" end,
      get_display_url: fn data -> "admin-management.roles({ roleId: '#{data.id}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "adminRoles.reprioritize" do
    %{
      get_display_text: fn _ -> "reordered role priorities" end,
      get_display_url: fn _ -> "admin-management.roles" end,
      data_query: fn data ->
        priorities =
          Enum.reduce(Role.all(), %{}, fn role, acc ->
            Map.put(acc, role.priority, %{
              :id => role.id,
              :lookup => role.lookup,
              :name => role.name
            })
          end)

        data = Map.put(data, :priorities, priorities)
        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "adminSettings.update" do
    %{
      get_display_text: fn _ -> "updated forum settings" end,
      get_display_url: fn _ -> "admin-settings" end
    }
  end

  def get_display_data(action_type) when action_type == "adminSettings.addToBlacklist" do
    %{
      get_display_text: fn data -> "added ip blacklist rule named '#{data.note}'" end,
      get_display_url: fn _ -> "admin-settings.advanced" end
    }
  end

  def get_display_data(action_type) when action_type == "adminSettings.updateBlacklist" do
    %{
      get_display_text: fn data -> "updated ip blacklist rule named '#{data.note}'" end,
      get_display_url: fn _ -> "admin-settings.advanced" end
    }
  end

  def get_display_data(action_type) when action_type == "adminSettings.deleteFromBlacklist" do
    %{
      get_display_text: fn data -> "deleted ip blacklist rule named '#{data.note}'" end,
      get_display_url: fn _ -> "admin-settings.advanced" end
    }
  end

  def get_display_data(action_type) when action_type == "adminSettings.setTheme" do
    %{
      get_display_text: fn _ -> "updated the forum theme" end,
      get_display_url: fn _ -> "admin-settings.theme" end
    }
  end

  def get_display_data(action_type) when action_type == "adminSettings.resetTheme" do
    %{
      get_display_text: fn _ -> "restored the forum to the default theme" end,
      get_display_url: fn _ -> "admin-settings.theme" end
    }
  end

  def get_display_data(action_type) when action_type == "adminUsers.addRoles" do
    %{
      get_display_text: fn data ->
        "added role '#{data.role_name}' to users(s) '#{Enum.join(data.usernames, ", ")}'"
      end,
      get_display_url: fn data -> "admin-management.roles({ roleId: '#{data.role_id}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(Role, id: data.role_id) do
            nil ->
              data

            role ->
              data
              |> Map.put(:role_name, role.name)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "adminUsers.removeRoles" do
    %{
      get_display_text: fn data ->
        "removed role '#{data.role_name}' from user '#{data.username}'"
      end,
      get_display_url: fn data -> "admin-management.roles({ roleId: '#{data.role_id}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(Role, id: data.role_id) do
            nil ->
              data

            role ->
              data
              |> Map.put(:role_name, role.name)
          end

        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "userNotes.create" do
    %{
      get_display_text: fn data ->
        "created a moderation note for user '#{data.username}'"
      end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "userNotes.update" do
    %{
      get_display_text: fn data ->
        "edited their moderation note for user '#{data.username}'"
      end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "userNotes.delete" do
    %{
      get_display_text: fn data ->
        "deleted their moderation note for user '#{data.username}'"
      end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "bans.addAddresses" do
    %{
      get_display_text: fn data ->
        addresses =
          Enum.reduce(data.addresses, [], fn address_info, acc ->
            address = address_info.hostname || address_info.ip
            [String.replace("#{address}", ~r/,/, ", ") | acc]
          end)

        "banned the following addresses '#{Enum.join(addresses, ", ")}'"
      end,
      get_display_url: fn _ -> "admin-management.banned-addresses" end
    }
  end

  def get_display_data(action_type) when action_type == "bans.editAddress" do
    %{
      get_display_text: fn data ->
        address = data.hostname || data.ip

        "edited banned address '#{String.replace("#{address}", ~r/%/, "*")}' to '#{if data.decay, do: "decay", else: "not decay"}' with a weight of '#{data.weight}'"
      end,
      get_display_url: fn data ->
        "admin-management.banned-addresses({ search: '#{data.hostname || data.ip}' })"
      end
    }
  end

  def get_display_data(action_type) when action_type == "bans.deleteAddress" do
    %{
      get_display_text: fn data ->
        address = data.hostname || data.ip
        "deleted banned address '#{String.replace("#{address}", ~r/%/, "*")}'"
      end,
      get_display_url: fn _ -> "admin-management.banned-addresses" end
    }
  end

  def get_display_data(action_type) when action_type == "bans.ban" do
    %{
      get_display_text: fn data ->
        formatted_date = Calendar.strftime(data.expiration, "%d %b %Y")

        if formatted_date != nil,
          do: "temporarily banned user '#{data.username}' until '#{formatted_date}'",
          else: "permanently banned user '#{data.username}'"
      end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "bans.unban" do
    %{
      get_display_text: fn data -> "unbanned user '#{data.username}'" end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "bans.banFromBoards" do
    %{
      get_display_text: fn data ->
        "banned user '#{data.username}' from boards: #{data.boards}'"
      end,
      get_display_url: fn _ -> "^.board-bans" end,
      data_query: fn data ->
        boards =
          Enum.reduce(data.board_ids, [], fn board_id, acc ->
            case Repo.get_by(Board, id: board_id) do
              nil -> acc
              board -> [board.name | acc]
            end
          end)

        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
              |> Map.put(:boards, Enum.join(boards, ", "))
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "bans.unbanFromBoards" do
    %{
      get_display_text: fn data ->
        "unbanned user '#{data.username}' from boards: #{data.boards}'"
      end,
      get_display_url: fn _ -> "^.board-bans" end,
      data_query: fn data ->
        boards =
          Enum.reduce(data.board_ids, [], fn board_id, acc ->
            case Repo.get_by(Board, id: board_id) do
              nil -> acc
              board -> [board.name | acc]
            end
          end)

        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
              |> Map.put(:boards, Enum.join(boards, ", "))
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "boards.create" do
    %{
      get_display_text: fn data ->
        board_names =
          Enum.reduce(data.boards, [], fn board, acc ->
            [String.replace("#{board.name}", ~r/,/, ", ") | acc]
          end)

        "created board named '#{Enum.join(board_names, ", ")}'"
      end,
      get_display_url: fn _ -> "admin-management.boards" end
    }
  end

  def get_display_data(action_type) when action_type == "boards.update" do
    %{
      get_display_text: fn data ->
        board_names =
          Enum.reduce(data.boards, [], fn board, acc ->
            [String.replace("#{board.name}", ~r/,/, ", ") | acc]
          end)

        "updated board named '#{Enum.join(board_names, ", ")}'"
      end,
      get_display_url: fn _ -> "admin-management.boards" end
    }
  end

  def get_display_data(action_type) when action_type == "boards.delete" do
    %{
      get_display_text: fn data -> "deleted board named '#{data.names}'" end,
      get_display_url: fn _ -> "admin-management.boards" end
    }
  end

  def get_display_data(action_type) when action_type == "threads.title" do
    %{
      get_display_text: fn data ->
        "updated the title of a thread created by user '#{data.author.username}' to '#{data.title}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        retrieve_thread(data)
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.lock" do
    %{
      get_display_text: fn data ->
        prefix = if data.locked, do: "locked", else: "unlocked"
        "'#{prefix}' the thread '#{data.title}' created by user '#{data.author.username}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        data = retrieve_thread(data)

        data = Map.put(data, :title, data.post.content["title"])
        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.sticky" do
    %{
      get_display_text: fn data ->
        prefix = if data.stickied, do: "stickied", else: "unstickied"
        "'#{prefix}' the thread '#{data.title}' created by user '#{data.author.username}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        data = retrieve_thread(data)

        data = Map.put(data, :title, data.post.content["title"])
        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.move" do
    %{
      get_display_text: fn data ->
        "moved the thread '#{data.title}' created by user '#{data.author.username}' from board '#{data.old_board_name}' to '#{data.new_board_name}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        data = retrieve_thread(data)

        data =
          case Repo.get_by(Board, id: data.new_board_id) do
            nil ->
              data

            board ->
              data
              |> Map.put(:new_board_name, board.name)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.purge" do
    %{
      get_display_text: fn data ->
        "purged thread '#{data.title}' created by user '#{data.author.username}' from board '#{data.old_board_name}'"
      end,
      get_display_url: fn _ -> nil end,
      data_query: fn data ->
        case Repo.get_by(User, id: data.user_id) do
          nil ->
            data

          user ->
            author = %{id: user.id, username: user.username, email: user.email}

            data
            |> Map.delete(:user_id)
            |> Map.put(:author, author)
        end
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.editPoll" do
    %{
      get_display_text: fn data ->
        "edited a poll in thread named '#{data.thread_title}' created by user '#{data.author.username}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        data = retrieve_thread(data)

        data = Map.put(data, :thread_title, data.post.content["title"])
        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.createPoll" do
    %{
      get_display_text: fn data ->
        "created a poll in thread named '#{data.thread_title}' created by user '#{data.author.username}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        data = retrieve_thread(data)

        data = Map.put(data, :thread_title, data.post.content["title"])
        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "threads.lockPoll" do
    %{
      get_display_text: fn data ->
        prefix = if data.locked, do: "locked", else: "unlocked"

        "'#{prefix}' poll in thread named '#{data.thread_title}' created by user '#{data.author.username}'"
      end,
      get_display_url: fn data -> "posts.data({ slug: '#{data.slug}' })" end,
      data_query: fn data ->
        data = retrieve_thread(data)

        data = Map.put(data, :thread_title, data.post.content["title"])
        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "posts.update" do
    %{
      get_display_text: fn data ->
        "updated post created by user '#{data.author.username}' in thread named '#{data.thread_title}'"
      end,
      get_display_url: fn data ->
        "posts.data({ slug: '#{data.slug}', start: '#{data.position}', '#': '#{data.id}' })"
      end,
      data_query: fn data -> retrieve_post(data) end
    }
  end

  def get_display_data(action_type) when action_type == "posts.delete" do
    %{
      get_display_text: fn data ->
        "hid post created by user '#{data.author.username}' in thread '#{data.thread_title}'"
      end,
      get_display_url: fn data ->
        "posts.data({ slug: '#{data.slug}', start: '#{data.position}', '#': '#{data.id}' })"
      end,
      data_query: fn data -> retrieve_post(data) end
    }
  end

  def get_display_data(action_type) when action_type == "posts.undelete" do
    %{
      get_display_text: fn data ->
        "unhid post created by user '#{data.author.username}' in thread '#{data.thread_title}'"
      end,
      get_display_url: fn data ->
        "posts.data({ slug: '#{data.slug}', start: '#{data.position}', '#': '#{data.id}' })"
      end,
      data_query: fn data -> retrieve_post(data) end
    }
  end

  def get_display_data(action_type) when action_type == "posts.purge" do
    %{
      get_display_text: fn data ->
        "purged post created by user '#{data.author.username}' in thread '#{data.thread_title}'"
      end,
      get_display_url: fn data ->
        "posts.data({ slug: '#{data.slug}' })"
      end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.user_id) do
            nil ->
              data

            user ->
              author = %{id: user.id, username: user.username, email: user.email}

              data
              |> Map.put(:author, author)
          end

        data =
          case Repo.get_by(Thread, id: data.thread_id) |> Repo.preload([:posts]) do
            nil ->
              data

            thread ->
              post = List.first(thread.posts)

              data
              |> Map.put(:slug, thread.slug)
              |> Map.put(:thread_title, post.content["title"])
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "users.update" do
    %{
      get_display_text: fn data -> "Updated user account '#{data.username}'" end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end
    }
  end

  def get_display_data(action_type) when action_type == "users.deactivate" do
    %{
      get_display_text: fn data -> "deactivated user account '#{data.username}'" end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
              |> Map.put(:email, user.email)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "users.reactivate" do
    %{
      get_display_text: fn data -> "reactivated user account '#{data.username}'" end,
      get_display_url: fn data -> "profile({ username: '#{data.username}' })" end,
      data_query: fn data ->
        data =
          case Repo.get_by(User, id: data.id) do
            nil ->
              data

            user ->
              data
              |> Map.put(:username, user.username)
              |> Map.put(:email, user.email)
          end

        data
      end
    }
  end

  def get_display_data(action_type) when action_type == "users.delete" do
    %{
      get_display_text: fn data -> "purged user account '#{data.username}'" end,
      get_display_url: fn _ -> nil end
    }
  end

  def get_display_data(action_type) when action_type == "conversations.delete" do
    %{
      get_display_text: fn data ->
        receiver_usernames =
          Enum.reduce(data.receivers, [], fn receiver, acc ->
            [String.replace("#{receiver.username}", ~r/,/, ", ") | acc]
          end)

        "deleted conversation between users '#{data.sender.username}' and '#{Enum.join(receiver_usernames, ", ")}'"
      end,
      get_display_url: fn _ -> nil end,
      data_query: fn data -> retrieve_participants(data) end
    }
  end

  def get_display_data(action_type) when action_type == "messages.delete" do
    %{
      get_display_text: fn data ->
        receiver_usernames =
          Enum.reduce(data.receivers, [], fn receiver, acc ->
            [String.replace("#{receiver.username}", ~r/,/, ", ") | acc]
          end)

        "deleted message sent between users '#{data.sender.username}' and '#{Enum.join(receiver_usernames, ", ")}'"
      end,
      get_display_url: fn _ -> nil end,
      data_query: fn data -> retrieve_participants(data) end
    }
  end

  def get_display_data(_action_type) do
    %{
      get_display_text: fn _ -> nil end,
      get_display_url: fn _ -> nil end
    }
  end

  defp replace_key_value(new_map, new_key, origin_map, origin_key) do
    if Map.has_key?(origin_map, origin_key) do
      Map.put(new_map, new_key, Map.get(origin_map, origin_key))
    else
      new_map
    end
  end

  defp retrieve_thread(data) do
    thread_id = data.thread_id || data.id

    data =
      case Repo.get_by(Thread, id: thread_id) |> Repo.preload([:posts]) do
        nil ->
          data

        thread ->
          post = List.first(thread.posts) |> Repo.preload([:user])

          author = %{id: post.user.id, username: post.user.username}

          data =
            data
            |> Map.put(:slug, thread.slug)
            |> Map.put(:author, author)
            |> Map.put(:post, post)
            |> Map.put(:thread, thread)

          data
      end

    data
  end

  defp retrieve_post(data) do
    data =
      case Repo.get_by(Post, id: data.id) |> Repo.preload([:user]) do
        nil ->
          data

        post ->
          author = %{username: post.user.username, id: post.user.id}

          data
          |> Map.put(:position, post.position)
          |> Map.put(:author, author)
          |> Map.put(:post, post)
          |> Map.put(:thread_id, post.thread_id)
          |> Map.put(:thread_title, post.content["title"])
      end

    data =
      case Repo.get_by(Thread, id: data.thread_id) do
        nil ->
          data

        thread ->
          data
          |> Map.put(:slug, thread.slug)
      end

    data
  end

  defp retrieve_participants(data) do
    data =
      case Repo.get_by(User, id: data.sender_id) do
        nil ->
          data

        sender ->
          sender_info = %{id: sender.id, username: sender.username, email: sender.email}

          data
          |> Map.delete(:sender_id)
          |> Map.put(:sender, sender_info)
      end

    receivers =
      Enum.reduce(data.receiver_ids, [], fn id, acc ->
        case(Repo.get_by(User, id: id)) do
          nil -> acc
          user -> [%{id: user.id, username: user.username, email: user.email} | acc]
        end
      end)

    data =
      data
      |> Map.put(:receivers, receivers)

    data
  end
end
