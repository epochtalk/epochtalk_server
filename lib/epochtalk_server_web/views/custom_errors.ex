defmodule EpochtalkServerWeb.CustomErrors do
  @auth_prefix "Auth:"

  # Auth errors
  defmodule InvalidCredentials do
    @moduledoc """
    Exception raised when user and password are not correct
    """
    defexception plug_status: 400, message: "#{auth_prefix} Invalid credentials", conn: nil, router: nil
  end
  defmodule NotLoggedIn do
    @moduledoc """
    Exception raised when user is not logged in
    """
    defexception plug_status: 400, message: "#{auth_prefix} Not logged in", conn: nil, router: nil
  end
  defmodule AccountNotConfirmed do
    @moduledoc """
    Exception raised when user's account is not confirmed
    """
    defexception plug_status: 400, message: "#{auth_prefix} User account not confirmed", conn: nil, router: nil
  end
end
