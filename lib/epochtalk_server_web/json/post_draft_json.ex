defmodule EpochtalkServerWeb.Controllers.PostDraftJSON do
  @moduledoc """
  Renders and formats `PostDraft` data, in JSON format for frontend
  """

  @doc """
  Renders `PostDraft` upsert result data in JSON

    ## Example
    iex> draft_data = %{
    iex>   user_id: 99,
    iex>   draft: "Hello world",
    iex>   updated_at: ~N[2024-03-12 01:28:15]
    iex> }
    iex> EpochtalkServerWeb.Controllers.PostDraftJSON.upsert(%{draft_data: draft_data})
    draft_data
  """
  def upsert(%{draft_data: draft_data}), do: draft_data

  @doc """
  Renders `PostDraft` by_user_id result data in JSON

    ## Example
    iex> EpochtalkServerWeb.Controllers.PostDraftJSON.by_user_id(%{draft_data: nil, user_id: 98})
    %{user_id: 98, draft: nil, updated_at: nil}
    iex> draft_data = %{
    iex>   user_id: 98,
    iex>   draft: "Hello world",
    iex>   updated_at: ~N[2024-03-12 01:28:15]
    iex> }
    iex> EpochtalkServerWeb.Controllers.PostDraftJSON.by_user_id(%{draft_data: draft_data, user_id: 98})
    draft_data
  """
  def by_user_id(%{draft_data: nil, user_id: user_id}),
    do: %{user_id: user_id, draft: nil, updated_at: nil}

  def by_user_id(%{draft_data: draft_data, user_id: _user_id}), do: draft_data
end
