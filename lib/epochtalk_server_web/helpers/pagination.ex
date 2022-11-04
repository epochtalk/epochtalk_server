defmodule EpochtalkServerWeb.Helpers.Pagination do
  @moduledoc """
  Helper for paginating database queries
  """
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServerWeb.Helpers.Validate

  @doc """
  Takes in a query, page and per_page option, returns paginated data and relevant
  pagination data for frontend (ex. page, limit, next, prev)

  ## Example
      iex> import Ecto.Query
      iex> alias EpochtalkServer.Models.{ User, Role }
      iex> alias EpochtalkServerWeb.Helpers.Pagination
      iex> User
      ...> |> order_by(asc: :id)
      ...> |> Pagination.page_simple(1, per_page: 25)
      {:ok, [], %{limit: 25, next: false, page: 1, prev: false}}
      iex> Role
      ...> |> order_by(desc: :lookup)
      ...> |> Pagination.page_simple(1, per_page: 10)
      {:ok, [], %{limit: 10, next: false, page: 1, prev: false}}
  """
  @spec page_simple(query :: Ecto.Queryable.t(), page :: integer | String.t() | nil, per_page: integer | String.t() | nil) :: {:ok, list :: [term()] | [], pagination_data :: map()}
  def page_simple(query, nil, per_page: nil),
    do: page_simple(query, 1, per_page: 25)
  def page_simple(query, nil, per_page: per_page) when is_binary(per_page),
    do: page_simple(query, 1, per_page: Validate.optional_pos_int(per_page, "limit"))
  def page_simple(query, page, per_page: nil) when is_binary(page),
    do: page_simple(query, Validate.optional_pos_int(page, "page"), per_page: 25)
  def page_simple(query, page, per_page: per_page) when is_binary(page) and is_binary(per_page),
    do: page_simple(query, Validate.optional_pos_int(page, "page"), per_page: Validate.optional_pos_int(per_page, "limit"))
  def page_simple(query, page, per_page: per_page) do
    result = query
      |> limit(^per_page+1) # query one extra to see if there's a next page
      |> offset(^((page*per_page)-per_page))
      |> Repo.all(prefix: "public")
    next = length(result) > per_page # next page exists if extra record is returned
    result = if next, # remove extra record if necessary
      do: result |> Enum.reverse() |> tl() |> Enum.reverse(),
      else: result
    pagination_data = %{
      next: next,
      prev: page > 1,
      page: page,
      limit: per_page
    }
    {:ok, result, pagination_data}
  end
end
