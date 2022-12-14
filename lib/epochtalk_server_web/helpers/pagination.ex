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
      iex> alias EpochtalkServer.Models.{ Mention, Invitation }
      iex> alias EpochtalkServerWeb.Helpers.Pagination
      iex> Mention
      ...> |> order_by(asc: :id)
      ...> |> Pagination.page_simple(1, per_page: 25)
      {:ok, [], %{limit: 25, next: false, page: 1, prev: false}}
      iex> Invitation
      ...> |> order_by(desc: :email)
      ...> |> Pagination.page_simple(1, per_page: 10)
      {:ok, [], %{limit: 10, next: false, page: 1, prev: false}}
  """
  @spec page_simple(query :: Ecto.Queryable.t(), page :: integer | String.t() | nil,
          per_page: integer | String.t() | nil
        ) :: {:ok, list :: [term()] | [], pagination_data :: map()}
  def page_simple(query, nil, per_page: nil),
    do: page_simple(query, 1, per_page: 25)

  def page_simple(query, page, per_page: nil) when is_integer(page),
    do: page_simple(query, page, per_page: 25)

  def page_simple(query, nil, per_page: per_page) when is_integer(per_page),
    do: page_simple(query, 1, per_page: per_page)

  def page_simple(query, nil, per_page: per_page) when is_binary(per_page),
    do:
      page_simple(query, 1, per_page: Validate.cast_str(per_page, :integer, key: "limit", min: 1))

  def page_simple(query, page, per_page: nil) when is_binary(page),
    do: page_simple(query, Validate.cast_str(page, :integer, key: "page", min: 1), per_page: 25)

  def page_simple(query, page, per_page: per_page) when is_binary(page) and is_binary(per_page),
    do:
      page_simple(query, Validate.cast_str(page, :integer, key: "page", min: 1),
        per_page: Validate.cast_str(per_page, :integer, key: "limit", min: 1)
      )

  def page_simple(query, page, per_page: per_page) do
    result =
      query
      # query one extra to see if there's a next page
      |> limit(^(per_page + 1))
      |> offset(^(page * per_page - per_page))
      |> Repo.all(prefix: "public")

    # next page exists if extra record is returned
    next = length(result) > per_page
    # remove extra record if necessary
    result =
      if next,
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
