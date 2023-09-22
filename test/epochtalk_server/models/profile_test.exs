defmodule Test.EpochtalkServer.Models.Profile do
  use Test.Support.DataCase, async: true
  alias EpochtalkServer.Models.Profile

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
