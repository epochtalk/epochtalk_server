defmodule Test.Support.Factories.PostDraft do
  @moduledoc """
  Factory for `PostDraft`
  """
  alias EpochtalkServer.Models.PostDraft

  defmacro __using__(_opts) do
    quote do
      def post_draft_factory(
            %{
              user_id: user_id,
              draft: draft
            } = attrs
          ) do
        PostDraft.upsert(user_id, %{"draft" => draft})
        |> case do
          {:ok, draft} -> draft
        end
      end
    end
  end
end
