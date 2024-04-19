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

    @tag authenticated: :admin
    test "given empty list, succeeds", %{
      conn: conn
    } do
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload), %{images: []})
        |> json_response(200)
      assert Map.keys(response) == ["presigned_posts"]
      assert Map.keys(response["presigned_posts"]) |> length() == 0
    end

    @tag authenticated: :admin
    test "given list with one image, succeeds", %{
      conn: conn
    } do
      images = [
        %{
          "length" => 100,
          "file_type" => "jpeg"
        }
      ]
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload), %{images: images})
        |> json_response(200)
      assert Map.keys(response) == ["presigned_posts"]
      assert Map.keys(response["presigned_posts"]) |> length() == 1
    end

    @tag authenticated: :admin
    test "given list with ten images, succeeds", %{
      conn: conn
    } do
      images = [
        %{
          "length" => 100,
          "file_type" => "jpeg"
        },
        %{
          "length" => 200,
          "file_type" => "png"
        },
        %{
          "length" => 300,
          "file_type" => "gif"
        },
        %{
          "length" => 400,
          "file_type" => "tiff"
        },
        %{
          "length" => 500,
          "file_type" => "vnd.microsoft.icon"
        },
        %{
          "length" => 600,
          "file_type" => "x-icon"
        },
        %{
          "length" => 700,
          "file_type" => "vnd.djvu"
        },
        %{
          "length" => 800,
          "file_type" => "svg+xml"
        },
        %{
          "length" => 900,
          "file_type" => "jpeg"
        },
        %{
          "length" => 1000,
          "file_type" => "jpeg"
        }
      ]
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload), %{images: images})
        |> json_response(200)
      assert Map.keys(response) == ["presigned_posts"]
      assert Map.keys(response["presigned_posts"]) |> length() == 10
    end

    @tag authenticated: :admin
    test "given list with eleven images, fails with bad request", %{
      conn: conn
    } do
      images = [
        %{
          "length" => 100,
          "file_type" => "jpeg"
        },
        %{
          "length" => 200,
          "file_type" => "png"
        },
        %{
          "length" => 300,
          "file_type" => "gif"
        },
        %{
          "length" => 400,
          "file_type" => "tiff"
        },
        %{
          "length" => 500,
          "file_type" => "vnd.microsoft.icon"
        },
        %{
          "length" => 600,
          "file_type" => "x-icon"
        },
        %{
          "length" => 700,
          "file_type" => "vnd.djvu"
        },
        %{
          "length" => 800,
          "file_type" => "svg+xml"
        },
        %{
          "length" => 900,
          "file_type" => "jpeg"
        },
        %{
          "length" => 1000,
          "file_type" => "jpeg"
        },
        %{
          "length" => 1100,
          "file_type" => "jpeg"
        }
      ]
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload), %{images: images})
        |> json_response(400)
      assert response["error"] == "Bad Request"
      assert response["message"] == "Requested images amount 11 exceeds max of 10"
    end
  end
end
