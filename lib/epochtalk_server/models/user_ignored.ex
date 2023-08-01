defmodule EpochtalkServer.Models.UserIgnored do
  use Ecto.Schema
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserIgnored

  @moduledoc """
  `UserIgnored` model, for performing actions relating to `UserIgnored`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          ignored_user_id: non_neg_integer | nil,
          created_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :ignored_user_id,
             :created_at
           ]}
  @schema_prefix "users"
  @primary_key false
  schema "ignored" do
    belongs_to :user, User
    belongs_to :ignored_user, User
    field :created_at, :naive_datetime
  end

  ## === Database Functions ===

  @doc """
  Used to get `UserIgnored` data for a specific `User` on a list of `user_id`
  """
  @spec by_user_ids(user_id :: non_neg_integer, user_ids :: [non_neg_integer]) ::
          ignored_users_list :: [non_neg_integer]
  def by_user_ids(user_id, user_ids) when is_integer(user_id) and is_list(user_ids) do
    query =
      from u in UserIgnored,
        where: u.user_id == ^user_id and u.ignored_user_id in ^user_ids,
        select: u.ignored_user_id

    Repo.all(query)
  end
end
