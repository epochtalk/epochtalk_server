defmodule Test.Support.Factory do
  @moduledoc """
  Consolidates access to test factories in the project
  """

  # see thoughtbot/ex_machina for docs
  use ExMachina.Ecto, repo: EpochtalkServer.Repo

  use Test.Support.Factories.BoardMapping
  use Test.Support.Factories.Category
  use Test.Support.Factories.Board
end
