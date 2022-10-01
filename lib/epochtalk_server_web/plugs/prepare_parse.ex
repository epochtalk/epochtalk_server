defmodule EpochtalkServerWeb.Plugs.PrepareParse do
  import Plug.Conn
  use Phoenix.Controller
  alias EpochtalkServerWeb.ErrorView
  @env Application.compile_env(:application_api, :env)
  @methods ~w(POST PUT PATCH)

  def init(opts), do: opts

  def call(conn, opts) do
    %{method: method} = conn

    if method in @methods and not (@env in [:test]) do
      case Plug.Conn.read_body(conn, opts) do
        {:error, :timeout} -> raise Plug.TimeoutError
        {:error, _} -> raise Plug.BadRequestError
        {:more, _, conn} -> render_error(conn, %{message: "Payload too large error"})
        {:ok, "" = body, conn} -> update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {:ok, body, conn} ->
          case Jason.decode(body) do
            {:ok, _result} -> update_in(conn.assigns[:raw_body], &[body | &1 || []])
            {:error, _reason} -> render_error(conn, %{message: "Malformed JSON in the body"})
          end
      end
    else conn end
  end

  def render_error(conn, %{ message: message } = _error) do
    conn
    |> put_status(400)
    |> put_view(ErrorView)
    |> render("400.json", message: message)
  end
end
