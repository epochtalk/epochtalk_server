defmodule EpochtalkServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :epochtalk_server
  alias EpochtalkServerWeb.Endpoint.CacheBodyReader

  # get x-forwarded ip
  plug RemoteIp

  # cors configuration
  plug Corsica, origins: "*", allow_headers: :all

  socket "/socket", EpochtalkServerWeb.UserSocket,
    websocket: true,
    longpoll: false

  # socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :epochtalk_server,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :epochtalk_server
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  # handle malformed json payload
  plug EpochtalkServerWeb.Plugs.PrepareParse

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    body_reader: {CacheBodyReader, :read_body, []},
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug EpochtalkServerWeb.Router
end

# used to help preparse raw req body, in case of malformed payload
defmodule EpochtalkServerWeb.Endpoint.CacheBodyReader,
  do: def(read_body(conn, _opts), do: {:ok, conn.assigns.raw_body, conn})
