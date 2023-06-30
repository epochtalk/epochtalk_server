defmodule Test.Support.Factory do
  # see thoughtbot/ex_machina for docs
  use ExMachina.Ecto, repo: EpochtalkServer.Repo

  use Test.Support.Factories.Category
end
