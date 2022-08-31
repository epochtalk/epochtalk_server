defmodule EpochtalkServerWeb.CustomErrors do
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
end
