defmodule Test.Support.Factories.Poll do
  @moduledoc """
  Factory for `Poll`
  """
  defmacro __using__(_opts) do
    quote do
      def poll_attributes_factory(%{} = attrs) do
        %{
          "question" => Map.get(attrs, :question) || "Is this a thread with a poll?",
          "max_answers" => Map.get(attrs, :max_answers) || 1,
          "answers" => Map.get(attrs, :answers) || ["Yes", "No"],
          "change_vote" => Map.get(attrs, :change_vote) || false,
          "display_mode" => Map.get(attrs, :display_mode) || "always",
          "locked" => Map.get(attrs, :locked) || false,
          "expiration" => Map.get(attrs, :expiration) || nil
        }
      end

      # polls are created when creating a thread currently
      def poll_factory(%{} = attrs), do: poll_attributes_factory(attrs)
    end
  end
end
