defmodule Test.Support.Factories.Mention do
  @moduledoc """
  Factory for `Mention`
  """
  alias EpochtalkServer.Models.Mention

  defmacro __using__(_opts) do
    quote do
      def mention_factory(
            %{
              thread_id: thread_id,
              post_id: post_id,
              mentioner_id: mentioner_id,
              mentionee_id: mentionee_id
            } = attrs
          ) do
        mention_attributes = %{
          "thread_id" => thread_id,
          "post_id" => post_id,
          "mentioner_id" => mentioner_id,
          "mentionee_id" => mentionee_id
        }

        Mention.create(mention_attributes)
        |> case do
          {:ok, mention} ->
            build(:notification, %{
              mention_id: mention.id,
              type: "mention",
              action: "refreshMentions",
              sender_id: mentioner_id,
              receiver_id: mentionee_id
            })

            mention
        end
      end
    end
  end
end
