defmodule EpochtalkServer.Models.AutoModeration do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.AutoModeration

  @postgres_varchar255_max 255
  @postgres_varchar1000_max 1000

  @moduledoc """
  `AutoModeration` model, for performing actions relating to `User` `AutoModeration`
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          message: String.t() | nil,
          conditions: map | nil,
          actions: map | nil,
          options: map | nil,
          created_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :description,
             :message,
             :conditions,
             :actions,
             :options,
             :created_at,
             :updated_at
           ]}
  schema "auto_moderation" do
    field :name, :string
    field :description, :string
    field :message, :string
    field :conditions, {:array, :map}
    field :actions, {:array, :string}
    field :options, :map
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for `AutoModeration` model
  """
  @spec create_changeset(
          auto_moderation :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(auto_moderation, attrs \\ %{}) do
    auto_moderation
    |> cast(attrs, [
      :id,
      :name,
      :description,
      :message,
      :conditions,
      :actions,
      :options,
      :created_at,
      :updated_at
    ])
    |> unique_constraint(:id, name: :auto_moderation_pkey)
    |> validate_required([:name, :conditions, :actions])
    |> validate_length(:name, min: 1, max: @postgres_varchar255_max)
    |> validate_length(:description, max: @postgres_varchar1000_max)
    |> validate_length(:message, max: @postgres_varchar1000_max)
  end

  @doc """
  Creates an update changeset for `AutoModeration` model
  """
  @spec update_changeset(auto_moderation :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def update_changeset(auto_moderation, attrs \\ %{}) do
    updated_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    auto_moderation =
      auto_moderation
      |> Map.put(:updated_at, updated_at)

    auto_moderation
    |> cast(attrs, [
      :id,
      :name,
      :description,
      :message,
      :conditions,
      :actions,
      :options,
      :created_at,
      :updated_at
    ])
    |> validate_required([
      :id,
      :name,
      :conditions,
      :actions,
      :updated_at
    ])
  end

  ## === Database Functions ===

  @doc """
  Get all `AutoModeration` rules
  """
  @spec all() :: [t()]
  def all() do
    query = from(a in AutoModeration)
    Repo.all(query)
  end

  @doc """
  Add `AutoModeration` rule
  """
  @spec add(auto_moderation_attrs :: map()) :: auto_moderation_rule :: t()
  def add(auto_moderation_attrs) do
    auto_moderation_cs = create_changeset(%AutoModeration{}, auto_moderation_attrs)
    Repo.insert(auto_moderation_cs)
  end

  @doc """
  Remove `AutoModeration` rule
  """
  @spec remove(id :: non_neg_integer) :: {non_neg_integer(), nil | [term()]}
  def remove(id) do
    query =
      from a in AutoModeration,
        where: a.id == ^id

    Repo.delete_all(query)
  end

  @doc """
  Updates an existing `AutoModeration` rule in the database and reloads role cache
  """
  @spec update(auto_moderation_attrs :: map()) ::
          {:ok, auto_moderation :: Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(auto_moderation_attrs) do
    AutoModeration
    |> Repo.get(auto_moderation_attrs["id"])
    |> update_changeset(auto_moderation_attrs)
    |> Repo.update()
  end

  ## === Public Helper Functions ===

  @doc """
  Executes `AutoModeration` rules

  TODO(akinsey): Optimize and store rules in Redis so we dont have to query every request

  ### Rule Anatomy
  * Only works on posts
  * = Name: Name for this rule (for admin readability)
  * = Description: What this rule does (for admin readbility)
  * = Message: Error reported back to the user on reject action
  * = Conditions: condition regex will only work on
  *   - body
  *   - thread_id
  *   - user_id
  *   - title (although it's not much use)
  *   == REGEX IS AN OBJECT with a pattern and flag property
  *   Multiple conditions are allow but they all must pass to enable rule actions
  * = Actions: reject, ban, edit, delete (filter not yet implemented)
  * = Options:
  *   - banInterval:
  *      - Affects ban action.
  *      - Leave blank for permanent
  *      - Otherwise, JS date string
  *   - edit:
  *      - replace (replace chunks of text):
  *        - regex: Regex used to match post body
  *          - regex object has a pattern and flag property
  *        - text: Text used to replace any matches
  *      - template: String template used to add text above or below post body
  """
  @spec moderate(user :: map, post_attrs :: map) :: post_attrs :: map
  def moderate(%{id: user_id} = user, post_attrs) do
    rules = AutoModeration.all()
    acc_init = %{
      action_set: MapSet.new(),
      messages: [],
      ban_interval: nil,
      edits: []
    }
    %{
      action_set: action_set,
      messages: messages,
      ban_interval: ban_interval,
      edits: edits
    } = Enum.reduce(rules, acc_init, fn rule, acc ->
      if condition_is_valid?(post_attrs, rule.conditions) do
        # Aggregate all actions, using MapSet ensures actions are unique
        action_set = (MapSet.to_list(acc.action_set) ++ rule.actions) |> MapSet.new()

        # Aggregate all reject messages if applicable
        messages = if Enum.member?(rule.actions, "reject") and is_binary(rule.message),
          do: acc.messages ++ [rule.message]
          else: acc.messages

        # Pick the latest ban interval, in the event multiple are provided
        ban_interval = if Enum.member?(rules.actions, "ban") and acc.ban_interval < ,
          do:

        %{
          action_set: action_set,
          messages: messages,
          ban_interval: ban_interval,
          edits: edits
        }
      else
        acc
      end
    end)
    post_attrs
  end

  ## === Private Helper Functions ===

  defp condition_is_valid?(post_attrs, conditions) do
    matches = Enum.map(conditions, fn condition ->
      test_param = post_attrs[condition["param"]]
      test_pattern = condition["regex"]["pattern"]
      test_flags = condition["regex"]["flags"]
      # remove g flag, one match is good enough to determine if condition is valid
      test_flags = Regex.replace(~r/g/, test_flags, "")
      match_regex = Regex.compile!(test_pattern, test_flags)
      Regex.match?(match_regex, test_flags)
    end)

    # Only valid if every condition returns a valid regex match
    !Enum.member?(matches, false)
  end
end
