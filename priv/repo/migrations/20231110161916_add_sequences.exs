defmodule EpochtalkServer.Repo.Migrations.AddSequences do
  use Ecto.Migration

  def change do
    execute "ALTER SEQUENCE categories_id_seq RESTART WITH 50;"
    execute "ALTER SEQUENCE boards_id_seq RESTART WITH 500;"
    execute "ALTER SEQUENCE threads_id_seq RESTART WITH 2000000;"
    execute "ALTER SEQUENCE posts_id_seq RESTART WITH 60000000;"
  end
end
