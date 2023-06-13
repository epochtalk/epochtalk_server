defmodule Test.EpochtalkServerWeb.Controllers.ErrorJSON do
  use Test.Support.ConnCase, async: true

  # Specify that we want to use doctests:
  doctest EpochtalkServerWeb.Controllers.ErrorJSON

  test "renders 404.json" do
    assert EpochtalkServerWeb.Controllers.ErrorJSON.render("404.json", %{}) == %{
             error: "Not Found",
             message: "Request Error",
             status: 404
           }
  end

  test "renders 500.json" do
    assert EpochtalkServerWeb.Controllers.ErrorJSON.render("500.json", %{}) == %{
             error: "Internal Server Error",
             message: "Request Error",
             status: 500
           }
  end
end
