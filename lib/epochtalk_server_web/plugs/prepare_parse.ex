defmodule EpochtalkServerWeb.Plugs.PrepareParse do
  @moduledoc """
  Plug that pre-parses request body and raises errors if there are problems
  """
  alias EpochtalkServerWeb.CustomErrors.{
    MalformedPayload,
    OversizedPayload
  }

  @env Mix.env()
  @methods ~w(POST PUT PATCH)

  @doc """
  default Plug init function
  """
  def init(opts), do: opts

  @doc """
  Pre-parses request body and checks for errors with payload. (ex: Malformed JSON or Payload too large)
  """
  def call(conn, opts) do
    %{method: method} = conn

    if method in @methods and @env != :test do
      case Plug.Conn.read_body(conn, opts) do
        {:error, :timeout} -> raise Plug.TimeoutError
        {:error, _} -> raise Plug.BadRequestError
        {:more, _, _} -> raise OversizedPayload
        {:ok, "" = body, conn} -> update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {:ok, body, conn} -> try_decode(conn, body)
      end
    else
      conn
    end
  end

  defp try_decode(conn, body) do
    case Jason.decode(body) do
      {:ok, _result} -> update_in(conn.assigns[:raw_body], &[body | &1 || []])
      {:error, _reason} -> raise MalformedPayload
    end
  end
end
