defmodule EpochtalkServer.SmfRepo do
  use Ecto.Repo,
    otp_app: :epochtalk_server,
    adapter: Ecto.Adapters.MyXQL
end
