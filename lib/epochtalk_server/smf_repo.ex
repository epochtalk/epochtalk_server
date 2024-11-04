defmodule EpochtalkServer.SmfRepo do
  @moduledoc """
  SmfRepo, for connecting to old btct DB for proxy data pulling
  """
  use Ecto.Repo,
    otp_app: :epochtalk_server,
    adapter: Ecto.Adapters.MyXQL
end
