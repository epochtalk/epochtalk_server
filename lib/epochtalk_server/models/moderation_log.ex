defmodule EpochtalkServer.Models.ModerationLog do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.ModerationLog
  alias EpochtalkServerWeb.Helpers.Pagination

  @moduledoc """
  `ModerationLog` model, for performing actions relating to the moderation log
  """
  @type t :: %__MODULE__{
          mod_username: String.t() | nil,
          mod_id: non_neg_integer | nil,
          mod_ip: String.t() | nil,
          action_api_url: String.t() | nil,
          action_api_method: String.t() | nil,
          action_obj: map() | nil,
          action_taken_at: NaiveDateTime.t() | nil,
          action_type: String.t() | nil,
          action_display_text: String.t() | nil,
          action_display_url: String.t() | nil
        }
  schema "moderation_logs" do
    field :mod_username, :string
    field :mod_id, :integer
    field :mod_ip, :string
    field :action_api_url, :string
    field :action_api_method, :string
    field :action_obj, :map
    field :action_taken_at, :naive_datetime
    field :action_type, :string
    field :action_display_text, :string
    field :action_display_url, :string
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `ModerationLog` model
  """
  @spec changeset(moderation_log :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(moderation_log, attrs) do
    moderation_log
    |> cast(attrs, [
      :mod_username,
      :mod_id,
      :mod_ip,
      :action_api_url,
      :action_api_method,
      :action_obj,
      :action_taken_at,
      :action_type,
      :action_display_text,
      :action_display_url
    ])
  end

  ## === Database Functions ===

  @doc """
  Creates a new `ModerationLog` in the database
  """
  @spec create(attrs :: map()) :: {:ok, moderation_log :: t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    moderation_log_cs = ModerationLog.changeset(%ModerationLog{}, attrs)
    Repo.insert(moderation_log_cs)
  end

  @doc """
  Page `ModerationLog` models
  ### Valid Options
  | name        | type              | details                                             |
  | ----------- | ----------------- | --------------------------------------------------- |
  | `:per_page` | `non_neg_integer` | records per page to return                          |
  """
  @spec page(page :: non_neg_integer,
          per_page: non_neg_integer
        ) :: {:ok, moderation_log :: [t()] | [], pagination_data :: map()}
  # TODO (crod951) Write ModerationLog page query logic
  def page(page \\ 1, opts \\ []) do
    page_query(opts[:per_page])
    |> Pagination.page_simple(page, per_page: opts[:per_page])
  end

  defp page_query(per_page) do
    ModerationLog
    |> limit(^per_page)
    |> Repo.all()
  end
end
