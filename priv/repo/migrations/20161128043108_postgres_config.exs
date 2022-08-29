defmodule Epoch.Repo.Migrations.PostgresConfig do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public"
    execute "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog"

    execute "CREATE SCHEMA administration"
    execute "CREATE SCHEMA ads"
    execute "CREATE SCHEMA factoids"
    execute "CREATE SCHEMA mentions"
    execute "CREATE SCHEMA mod"
    execute "CREATE SCHEMA users"

    execute """
    CREATE TYPE moderation_action_type AS ENUM (
      'adminBoards.updateCategories',
      'adminModerators.add',
      'adminModerators.remove',
      'adminReports.createMessageReportNote',
      'adminReports.updateMessageReportNote',
      'adminReports.createPostReportNote',
      'adminReports.updatePostReportNote',
      'adminReports.createUserReportNote',
      'adminReports.updateUserReportNote',
      'adminReports.updateMessageReport',
      'adminReports.updatePostReport',
      'adminReports.updateUserReport',
      'adminRoles.add',
      'adminRoles.remove',
      'adminRoles.update',
      'adminRoles.reprioritize',
      'adminSettings.update',
      'adminSettings.addToBlacklist',
      'adminSettings.updateBlacklist',
      'adminSettings.deleteFromBlacklist',
      'adminSettings.setTheme',
      'adminSettings.resetTheme',
      'adminUsers.update',
      'adminUsers.addRoles',
      'adminUsers.removeRoles',
      'userNotes.create',
      'userNotes.update',
      'userNotes.delete',
      'bans.ban',
      'bans.unban',
      'bans.banFromBoards',
      'bans.unbanFromBoards',
      'bans.addAddresses',
      'bans.editAddress',
      'bans.deleteAddress',
      'boards.create',
      'boards.update',
      'boards.delete',
      'threads.title',
      'threads.sticky',
      'threads.createPoll',
      'threads.lock',
      'threads.move',
      'threads.lockPoll',
      'threads.purge',
      'threads.editPoll',
      'posts.update',
      'posts.undelete',
      'posts.delete',
      'posts.purge',
      'users.update',
      'users.delete',
      'users.reactivate',
      'users.deactivate',
      'conversations.delete',
      'messages.delete',
      'reports.createMessageReportNote',
      'reports.updateMessageReportNote',
      'reports.createPostReportNote',
      'reports.updatePostReportNote',
      'reports.createUserReportNote',
      'reports.updateUserReportNote',
      'reports.updateMessageReport',
      'reports.updatePostReport',
      'reports.updateUserReport'
    );
    """

    execute """
    CREATE TYPE polls_display_enum AS ENUM (
        'always',
        'voted',
        'expired'
    );
    """

    execute """
    CREATE TYPE report_status_type AS ENUM (
        'Pending',
        'Reviewed',
        'Ignored',
        'Bad Report'
    );
    """
  end
end
