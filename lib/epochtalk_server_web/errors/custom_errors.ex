defmodule EpochtalkServerWeb.CustomErrors do

  # Auth errors
  defmodule InvalidCredentials do
    @moduledoc """
    Exception raised when user and password are not correct
    """
    defexception plug_status: 400, message: "Invalid credentials", conn: nil, router: nil
  end

  defmodule NotLoggedIn do
    @moduledoc """
    Exception raised when user is not logged in
    """
    defexception plug_status: 400, message: "Not logged in", conn: nil, router: nil
  end

  defmodule AccountNotConfirmed do
    @moduledoc """
    Exception raised when user's account is not confirmed
    """
    defexception plug_status: 400, message: "User account not confirmed", conn: nil, router: nil
  end

  defmodule AccountMigrationNotComplete do
    @moduledoc """
    Exception raised when user's account is not fully migrated
    """
    defexception plug_status: 403, message: "User account migration not complete, please reset password", conn: nil, router: nil
  end

  # API parameter mismatch handling
  defmodule InvalidPayload do
    @moduledoc """
    Exception raised when api request payload is incorrect
    """
    defexception plug_status: 400, message: "Invalid payload, check that the request payload is correct", conn: nil, router: nil
  end
end
