defmodule EpochtalkServerWeb.Helpers.ProxyPagination do
  @moduledoc """
  Helper for paginating database queries
  """
  import Ecto.Query
  alias EpochtalkServer.SmfRepo
  alias EpochtalkServerWeb.Helpers.Validate

  @doc """
  Takes in a query, page and per_page option, returns paginated data and relevant
  pagination data for frontend (ex. page, limit, next, prev)

  ## Example
      iex> import Ecto.Query
      iex> alias EpochtalkServer.Models.{ Mention, Invitation }
      iex> alias EpochtalkServerWeb.Helpers.Pagination
      iex> Mention
      ...> |> order_by(asc: :id)
      ...> |> Pagination.page_simple(1, per_page: 25, desc: true)
      {:ok, [], %{next: false,
               page: 1,
               per_page: 25,
               prev: false,
               total_pages: 1,
               total_records: 0,
               desc: true}}
      iex> Invitation
      ...> |> order_by(desc: :email)
      ...> |> Pagination.page_simple(1, per_page: 10)
      {:ok, [], %{next: false,
               page: 1,
               per_page: 10,
               prev: false,
               total_pages: 1,
               total_records: 0,
               desc: true}}
  """
  @spec page_simple(
          query :: Ecto.Queryable.t(),
          count_query :: Ecto.Queryable.t(),
          page :: integer | String.t() | nil,
          per_page: integer | String.t() | nil,
          desc: boolean
        ) :: {:ok, list :: [term()] | [], pagination_data :: map()} | {:error, data :: any()}
  def page_simple(query, count_query, nil, per_page: nil, desc: desc),
    do: page_simple(query, count_query, 1, per_page: 15, desc: desc)

  def page_simple(query, count_query, page, per_page: nil, desc: desc) when is_integer(page),
    do: page_simple(query, count_query, page, per_page: 15, desc: desc)

  def page_simple(query, count_query, nil, per_page: per_page, desc: desc)
      when is_integer(per_page),
      do: page_simple(query, count_query, 1, per_page: per_page, desc: desc)

  def page_simple(query, count_query, nil, per_page: per_page, desc: desc)
      when is_binary(per_page),
      do:
        page_simple(query, count_query, 1,
          per_page: Validate.cast_str(per_page, :integer, key: "limit", min: 1),
          desc: desc
        )

  def page_simple(query, count_query, page, per_page: nil, desc: desc) when is_binary(page),
    do:
      page_simple(query, count_query, Validate.cast_str(page, :integer, key: "page", min: 1),
        per_page: 15,
        desc: desc
      )

  def page_simple(query, count_query, page, per_page: per_page, desc: desc)
      when is_binary(page) and is_binary(per_page),
      do:
        page_simple(query, count_query, Validate.cast_str(page, :integer, key: "page", min: 1),
          per_page: Validate.cast_str(per_page, :integer, key: "limit", min: 1),
          desc: desc
        )

  def page_simple(query, count_query, page, per_page: per_page, desc: desc) do
    options = [prefix: "public"]

    total_records =
      Keyword.get_lazy(options, :total_records, fn ->
        total_records(count_query)
      end)

    total_pages = total_pages(total_records, per_page)

    result = records(query, page, total_pages, per_page)

    pagination_data = %{
      next: page < total_pages,
      prev: page > 1,
      page: page,
      per_page: per_page,
      total_records: total_records,
      total_pages: total_pages,
      desc: desc
    }

    {:ok, result, pagination_data}
  end

  def page_next_prev(query, page, per_page: per_page, desc: desc) do
    # query one more page to calculate if next page exists
    result = records(query, page, nil, per_page + 1)

    next = length(result) > per_page

    pagination_data = %{
      next: next,
      prev: page > 1,
      page: page,
      per_page: per_page,
      desc: desc
    }

    # remove extra element
    result =
      if next,
        do: result |> Enum.reverse() |> tl() |> Enum.reverse(),
        else: result

    {:ok, result, pagination_data}
  end

  defp records(query, page, total_pages, per_page) when is_nil(total_pages) do
    query
    |> limit(^per_page)
    |> offset(^(per_page * (page - 1)))
    |> SmfRepo.all()
  end

  defp records(_, page, total_pages, _) when page > total_pages, do: []

  defp records(query, page, _, per_page) do
    query
    |> limit(^per_page)
    |> offset(^(per_page * (page - 1)))
    |> SmfRepo.all()
  end

  defp total_records(query) do
    total_records =
      query
      |> exclude(:preload)
      |> exclude(:order_by)
      |> SmfRepo.one()

    total_records[:count] || 0
  end

  defp total_pages(0, _), do: 1

  defp total_pages(total_records, per_page) do
    (total_records / per_page)
    |> Float.ceil()
    |> round
  end
end
