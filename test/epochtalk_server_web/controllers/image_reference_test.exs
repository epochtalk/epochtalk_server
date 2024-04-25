defmodule Test.EpochtalkServerWeb.Controllers.ImageReference do
  @moduledoc """
  This test sets async: false because it tests the RateLimiter,
  which is succeptible to interference from other tests
  """
  use Test.Support.ConnCase, async: false
  alias EpochtalkServerWeb.CustomErrors.InvalidPermission
  alias EpochtalkServer.RateLimiter
  import Test.Support.Factory

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

  describe "s3_request_upload/2, rate limiting" do
    @tag :authenticated
    test "performs up to 100 requests in an hour", %{
      conn: conn,
      users: %{
        user: user
      }
    } do
      # reset daily/hourly limits for user
      RateLimiter.reset_rate_limit(:s3_daily, user)
      RateLimiter.reset_rate_limit(:s3_hourly, user)
      # build ten image reference attrs
      image_reference_attrs = %{
        images: build_list(10, :image_reference_attributes, length: 1000, file_type: "jpeg")
      }
      # call :s3_request_upload ten times with ten images each
      Enum.each(1..10, fn _ ->
        response =
          conn
          |> post(Routes.image_reference_path(conn, :s3_request_upload), image_reference_attrs)
          |> json_response(200)
        assert Map.keys(response) == ["presigned_posts"]
        assert Map.keys(response["presigned_posts"]) |> length() == 10
      end)
      # call :s3_request_upload once more
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload), image_reference_attrs)
        |> json_response(429)
      assert response["error"] == "Too Many Requests"
      assert response["message"] == "Hourly upload rate limit exceeded (100)"
    end
  end
end
