defmodule Test.EpochtalkServerWeb.Helpers.Validate do
  use Test.Support.ConnCase, async: true
  alias EpochtalkServerWeb.Helpers.Validate
  doctest Validate

  test "mutually_exclusive/2" do
  ## Example
    iex> alias EpochtalkServerWeb.Helpers.Validate
    iex> attrs = %{"page" => 1}
    iex> Validate.mutually_exclusive!(attrs, ["page", "start"])
    :ok
    iex> attrs = %{"start" => 1}
    iex> Validate.mutually_exclusive!(attrs, ["page", "start"])
    :ok
    iex> Validate.mutually_exclusive!(attrs, ["start"])
    :ok
    iex> attrs = %{"page" => 1, "start" => 1}
    iex> Validate.mutually_exclusive!(attrs, ["page", "start"])
    ** (EpochtalkServerWeb.CustomErrors.InvalidPayload) The following payload parameters cannot be passed at the same time: page, start
  end
end
