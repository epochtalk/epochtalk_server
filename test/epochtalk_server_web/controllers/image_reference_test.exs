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
                     post(conn, Routes.image_reference_path(conn, :s3_request_upload), %{
                       images: []
                     })
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
      attrs = [{100, "jpeg"}]
      images = build(:image_reference_attributes, attrs)

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
      attrs = [
        {100, "jpeg"},
        {200, "png"},
        {300,"gif"},
        {400, "tiff"},
        {500, "vnd.microsoft.icon"},
        {600, "x-icon"},
        {700, "vnd.djvu"},
        {800, "svg+xml"},
        {900, "jpeg"},
        {1000, "jpeg"}
      ]
      images = build(:image_reference_attributes, attrs)

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
      attrs = [
        {100, "jpeg"},
        {200, "png"},
        {300,"gif"},
        {400, "tiff"},
        {500, "vnd.microsoft.icon"},
        {600, "x-icon"},
        {700, "vnd.djvu"},
        {800, "svg+xml"},
        {900, "jpeg"},
        {1000, "jpeg"},
        {1100, "jpeg"}
      ]
      images = build(:image_reference_attributes, attrs)

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

    @tag :authenticated
    test "performs up to 1000 requests in a day", %{
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

      # call :s3_request_upload one hundred times with ten images each
      # resetting hourly rate limits each ten times
      Enum.each(1..10, fn _ ->
        Enum.each(1..10, fn _ ->
          response =
            conn
            |> post(Routes.image_reference_path(conn, :s3_request_upload), image_reference_attrs)
            |> json_response(200)

          assert Map.keys(response) == ["presigned_posts"]
          assert Map.keys(response["presigned_posts"]) |> length() == 10
        end)

        # reset hourly limits for user
        RateLimiter.reset_rate_limit(:s3_hourly, user)
      end)

      # call :s3_request_upload once more
      response =
        conn
        |> post(Routes.image_reference_path(conn, :s3_request_upload), image_reference_attrs)
        |> json_response(429)

      assert response["error"] == "Too Many Requests"
      assert response["message"] == "Daily upload rate limit exceeded (1000)"
    end
  end
end
