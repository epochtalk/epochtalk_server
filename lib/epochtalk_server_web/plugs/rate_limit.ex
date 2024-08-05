defmodule EpochtalkServerWeb.Plugs.RateLimit do
  require Logger

  @moduledoc """
  Handles rate limiting for GET, PUT, POST, or PATCH operations
  """
  use Plug.Builder
  alias EpochtalkServer.Auth.Guardian

  alias EpochtalkServerWeb.CustomErrors.{
    RateLimitExceeded
  }

  import EpochtalkServer.RateLimiter, only: [check_rate_limited: 2]

  @method_to_atom_map %{
    "GET" => :get,
    "POST" => :post,
    "PUT" => :put,
    "PATCH" => :patch,
    "DELETE" => :delete
  }
  @methods @method_to_atom_map |> Map.keys()

  plug(:rate_limit_request)

  @doc """
  Stores `User` IP when `User` is performing actions that modify data in the database
  """
  def rate_limit_request(conn, _opts) do
    with :ok <- check_env(conn),
         %{method: method} <- conn,
         {:ok, method} <- atomize_method(method),
         conn_id <- get_conn_id(conn),
         # ensure rate limit not exceeded
         {:allow, allow_count} <- check_rate_limited(method, conn_id) do
      Logger.debug("#{method} count for conn #{conn_id}: #{allow_count}")
      conn
    else
      # bypass rate limits
      # use tuple form with _ to pass dialyzer
      {:bypass, _} ->
        conn

      {:get, count} ->
        raise RateLimitExceeded, message: "GET rate limit exceeded (#{count})"

      {:post, count} ->
        raise RateLimitExceeded, message: "POST rate limit exceeded (#{count})"

      {:put, count} ->
        raise RateLimitExceeded, message: "PUT rate limit exceeded (#{count})"

      {:patch, count} ->
        raise RateLimitExceeded, message: "PATCH rate limit exceeded (#{count})"

      {:delete, count} ->
        raise RateLimitExceeded, message: "DELETE rate limit exceeded (#{count})"
    end
  end

  defp check_env(conn) do
    if unquote(Mix.env() == :test) && !Map.get(conn, :enforce_rate_limit) do
      {:bypass, nil}
    else
      :ok
    end
  end

  defp atomize_method(method) do
    if method in @methods do
      {:ok, @method_to_atom_map[method]}
    else
      # bypass rate limiter if http request method is not supported
      {:bypass, nil}
    end
  end

  defp get_conn_id(conn) do
    case Guardian.Plug.current_resource(conn) do
      nil -> conn.remote_ip |> :inet_parse.ntoa() |> to_string
      %{id: id} -> id
    end
  end
end
