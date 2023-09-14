ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EpochtalkServer.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:mimic)

# prep modules for mocking
Mimic.copy(NaiveDateTime)
