defmodule EpochtalkServer.Repo do
  use Ecto.Repo,
    otp_app: :epochtalk_server,
    adapter: Ecto.Adapters.Postgres
end
