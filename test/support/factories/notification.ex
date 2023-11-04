defmodule Test.Support.Factories.Notification do
  @moduledoc """
  Factory for `Notification`
  """
  alias EpochtalkServer.Models.Notification

  defmacro __using__(_opts) do
    quote do
      def notification_factory(
            %{
              mention_id: mention_id,
              sender_id: sender_id,
              receiver_id: receiver_id,
              type: type,
              action: action
            } = attrs
          ) do
        notification_attributes = %{
          sender_id: sender_id,
          receiver_id: receiver_id,
          type: type,
          data: %{
            action: action,
            mention_id: mention_id
          }
        }

        Notification.create(notification_attributes)
        |> case do
          {:ok, mention} -> mention
        end
      end
    end
  end
end
