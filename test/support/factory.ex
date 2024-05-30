defmodule Test.Support.Factory do
  @moduledoc """
  Consolidates access to test factories in the project
  """

  # see thoughtbot/ex_machina for docs
  use ExMachina.Ecto, repo: EpochtalkServer.Repo

  use Test.Support.Factories.User
  use Test.Support.Factories.RoleUser
  use Test.Support.Factories.BoardMapping
  use Test.Support.Factories.Category
  use Test.Support.Factories.Board
  use Test.Support.Factories.Thread
  use Test.Support.Factories.Mention
  use Test.Support.Factories.Notification
  use Test.Support.Factories.Poll
  use Test.Support.Factories.PostDraft
  use Test.Support.Factories.BannedAddress
  use Test.Support.Factories.ModerationLog
  use Test.Support.Factories.ImageReference
end
