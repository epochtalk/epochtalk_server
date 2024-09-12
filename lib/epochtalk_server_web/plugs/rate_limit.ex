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

  import EpochtalkServer.RateLimiter, only: [check_rate_limited: 3]

  @methods [
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE"
  ]

  plug(:rate_limit_request)

  @doc """
  Stores `User` IP when `User` is performing actions that modify data in the database
  """
  def rate_limit_request(conn, _opts) do
    with :ok <- check_env(conn),
         %{method: method, request_path: path} <- conn,
         {:ok, method} <- validate_method(method),
         conn_id <- get_conn_id(conn),
         # ensure rate limit not exceeded for http
         {:allow, http_count} <- check_rate_limited(:http, method, conn_id),
         # ensure rate limit not exceeded for api
         api_path <- "#{method}:#{path}",
         {:allow, api_count} <- check_rate_limited(:api, api_path, conn_id) do
      Logger.debug("""
        #{method} http count for conn #{conn_id}: #{http_count}
        #{api_path} api count for conn #{conn_id}: #{api_count}
        """)
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

      {api_path, count} ->
        raise RateLimitExceeded, message: "#{api_path} rate limit exceeded (#{count})"
    end
  end

  defp check_env(conn) do
    if unquote(Mix.env() == :test) && !Map.get(conn, :enforce_rate_limit) do
      {:bypass, nil}
    else
      :ok
    end
  end

  defp validate_method(method) do
    if method in @methods do
      {:ok, method}
    else
      # bypass rate limiter if http request method is not supported
      {:bypass, nil}
    end
  end

  defp get_conn_id(conn) do
    case Guardian.Plug.current_resource(conn) do
      nil -> conn.remote_ip |> :inet.ntoa() |> to_string
      %{id: id} -> id
    end
  end
end
