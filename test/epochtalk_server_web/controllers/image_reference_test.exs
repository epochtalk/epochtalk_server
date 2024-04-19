defmodule Test.EpochtalkServerWeb.Controllers.ImageReference do
  use Test.Support.ConnCase, async: true
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission

  describe "s3_request_upload/2" do
    test "when unauthenticated, raises InvalidPermission error", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload))
        |> json_response(401)
      assert response["error"] == "Unauthorized"
    end

    @tag authenticated: :private
    test "when authenticated with invalid permissions, raises InvalidPermission error", %{
      conn: conn
    } do
      assert_raise InvalidPermission,
        ~r/^Forbidden, invalid permissions to perform this action/,
        fn ->
          post(conn, Routes.image_reference_path(conn, :s3_request_upload), %{images: []})
        end
    end
  end
end
