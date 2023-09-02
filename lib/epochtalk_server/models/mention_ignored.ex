defmodule EpochtalkServer.Models.MentionIgnored do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.MentionIgnored
  alias EpochtalkServer.Models.User
  alias EpochtalkServerWeb.Helpers.Pagination

  @moduledoc """
  `MentionIgnored` model, for performing actions relating to forum categories
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          ignored_user_id: non_neg_integer | nil
        }
  @schema_prefix "mentions"
  @primary_key false
  schema "ignored" do
    belongs_to :user, User
    belongs_to :ignored_user, User
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for `MentionIgnored` model
  """
  @spec create_changeset(mention_ignored :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(mention_ignored, attrs) do
    mention_ignored
    |> cast(attrs, [:user_id, :ignored_user_id])
    |> foreign_key_constraint(:user_id, name: :user_id_fkey)
    |> foreign_key_constraint(:ignored_user_id, name: :ignored_user_id_fkey)
    |> unique_constraint([:user_id, :ignored_user_id],
      name: :ignored_user_id_ignored_user_id_index
    )
  end

  ## === Database Functions ===

  @doc """
  Create a `MentionIgnored`
  """
  @spec create(mention_ignored_attrs :: map) ::
          {:ok, mention_ignored :: t()} | {:error, Ecto.Changeset.t()}
  def create(mention_attrs \\ %{}),
    do: create_changeset(%MentionIgnored{}, mention_attrs) |> Repo.insert(returning: true)

  @doc """
  Delete all `MentionIgnored` for a specific `User`. Unignores all for specified `User`
  """
  @spec delete_by_user_id(user_id :: non_neg_integer) ::
          {:ok, deleted :: boolean}
  def delete_by_user_id(user_id) when is_integer(user_id) do
    query =
      from m in MentionIgnored,
        where: m.user_id == ^user_id

    {num_deleted, _} = Repo.delete_all(query)

    {:ok, num_deleted > 0}
  end

  @doc """
  Delete specific `MentionIgnored`. Unignores a single `User`
  """
  @spec delete(user_id :: non_neg_integer, ignored_user_id :: non_neg_integer) ::
          {:ok, deleted :: boolean}
  def delete(user_id, ignored_user_id) when is_integer(user_id) and is_integer(ignored_user_id) do
    query =
      from m in MentionIgnored,
        where: m.user_id == ^user_id and m.ignored_user_id == ^ignored_user_id

    {num_deleted, _} = Repo.delete_all(query)

    {:ok, num_deleted > 0}
  end

  @doc """
  Check if `MentionIgnored` to see if `User` is being ignored specified `User
  """
  @spec is_user_ignored?(user_id :: non_neg_integer, ignored_user_id :: non_neg_integer) ::
          boolean
  def is_user_ignored?(user_id, ignored_user_id)
      when is_integer(user_id) and is_integer(ignored_user_id) do
    query =
      from m in MentionIgnored,
        where: m.user_id == ^user_id and m.ignored_user_id == ^ignored_user_id,
        select: true

    ignored = Repo.one(query)

    !!ignored
  end

  @doc """
  Page all users blocked from mentioning the specified `User`
  ### Valid Options
  | name        | type              | details                                             |
  | ----------- | ----------------- | --------------------------------------------------- |
  | `:per_page` | `non_neg_integer` | records per page to return                          |
  """
  @spec page_by_user_id(user_id :: non_neg_integer, page :: non_neg_integer,
          per_page: non_neg_integer
        ) :: {:ok, mention_ignored :: [t()] | [], pagination_data :: map()}
  def page_by_user_id(user_id, page \\ 1, opts \\ []) do
    page_query =
      from m in MentionIgnored,
        where: m.user_id == ^user_id,
        preload: [ignored_user: [:profile]]

    page_query
    |> Pagination.page_simple(page, per_page: opts[:per_page])
  end
end
