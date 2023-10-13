defmodule Test.EpochtalkServer.Models.Profile do
  use Test.Support.DataCase, async: true
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.User

  describe "upsert/2" do
    test "given valid user_id, updates user's profile", %{users: %{user: user}} do
      # check default fields
      assert user.profile.avatar == ""
      assert user.profile.position == nil
      assert user.profile.signature == nil
      assert user.profile.post_count == 0
      assert user.profile.fields == nil
      assert user.profile.raw_signature == nil
      assert user.profile.last_active == nil

      updated_attrs = %{
        avatar: "image.png",
        position: "position",
        signature: "signature",
        raw_signature: "raw_signature"
      }

      Profile.upsert(user.id, updated_attrs)
      {:ok, updated_user} = User.by_id(user.id)
      assert updated_user.profile.avatar == updated_attrs.avatar
      assert updated_user.profile.position == updated_attrs.position
      assert updated_user.profile.signature == updated_attrs.signature
      assert updated_user.profile.raw_signature == updated_attrs.raw_signature
    end
  end

  describe "create/2" do
    test "given invalid user_id, errors with Ecto.ConstraintError" do
      invalid_user_id = 0

      assert_raise Ecto.ConstraintError,
                   ~r/profiles_user_id_fkey/,
                   fn ->
                     Profile.create(invalid_user_id)
                   end
    end

    test "given an existing user_id, errors with Ecto.ConstraintError", %{users: %{user: user}} do
      assert_raise Ecto.ConstraintError,
                   ~r/profiles_user_id_index/,
                   fn ->
                     Profile.create(user.id)
                   end
    end
  end
end
