defmodule Test.Support.Factories.ModerationLog do
  @moduledoc """
  Factory for `ModerationLog`

  Usage:
  build(:moderation_log, action)
  """
  alias EpochtalkServer.Models.ModerationLog
  @mod_address "127.0.0.2"

  defmacro __using__(_opts) do
    quote do
      def moderation_log_factory(action) do
        %{
          mod: %{
            username: sequence(:moderation_log_username, &"#{action.type}#{&1}"),
            # 1, 2, 3 ...
            id: sequence(""),
            ip: @mod_address
          },
          action: action
        }
        |> ModerationLog.create()
        |> case do
          {:ok, moderation_log} -> moderation_log
        end
      end
    end
  end
end
