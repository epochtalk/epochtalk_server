defmodule Test.EpochtalkServer.Regex do
  use Test.Support.ConnCase, async: true

  describe "pattern/1" do
    test "given valid atom, gets pattern" do
      assert EpochtalkServer.Regex.pattern(:username_mention) != nil
      assert EpochtalkServer.Regex.pattern(:username_mention_curly) != nil
      assert EpochtalkServer.Regex.pattern(:user_id) != nil
    end
    test "given invalid atom, returns nil" do
      assert EpochtalkServer.Regex.pattern(:bad_atom) == nil
    end
  end
end
