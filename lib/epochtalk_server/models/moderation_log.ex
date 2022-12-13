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
  @primary_key false
  @derive {Jason.Encoder, only: [:mod_username, :mod_id, :mod_ip, :action_api_url, :action_api_method, :action_obj, :action_taken_at, :action_type, :action_display_text, :action_display_url]}
  schema "moderation_log" do
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
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    attrs =
      attrs
      |> Map.put(:action_taken_at, now)
      |> Map.put(:mod_username, get_in(attrs, [:mod, :username]))
      |> Map.put(:mod_id, get_in(attrs, [:mod, :id]))
      |> Map.put(:mod_ip, get_in(attrs, [:mod, :ip]))
      |> Map.put(:action_api_url, get_in(attrs, [:action, :api_url]))
      |> Map.put(:action_api_method, get_in(attrs, [:action, :api_method]))
      |> Map.put(:action_type, get_in(attrs, [:action, :type]))
      |> Map.put(:action_display_text, get_in(attrs, [:action, :display_text]))
      |> Map.put(:action_display_url, get_in(attrs, [:action, :display_url]))

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
    case Repo.insert(moderation_log_cs) do
      {:ok, moderation_log} ->
        {:ok, moderation_log}

      # changeset error
      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Page `ModerationLog` models
  """
  @spec page(attrs :: map()) :: {:ok, moderation_logs :: [t()] | []}
  # TODO (crod951) Write ModerationLog page query logic
  def page(attrs \\ []) do
    # TODO (crod951): Add checks for fields - page, limit, mod, action, keyword, bdate, adate, sdate, edate
    page_query(attrs)
    # |> Pagination.page_simple(page, per_page: attrs[:limit])
  end

  defp page_query(attrs) do
    moderation_logs =
      ModerationLog
      |> where(^filter_where(attrs))
      # |> limit(^attrs[:limit])
      |> Repo.all()
    {:ok, moderation_logs}
  end

  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"mod", mod}, dynamic ->
        like = "%#{mod}%"

        case Integer.parse(mod) do
          {num, ""} -> dynamic([q], q.mod_id == ^mod  and ^dynamic)
          _ -> dynamic([q], (ilike(q.mod_username, ^like) or ilike(q.mod_ip, ^like)) and ^dynamic)
        end

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
