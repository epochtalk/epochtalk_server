defmodule EpochtalkServer.Models.AutoModeration do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Session
  alias EpochtalkServer.Models.AutoModeration
  alias EpochtalkServer.Models.Ban
  alias EpochtalkServerWeb.CustomErrors.AutoModeratorReject

  @postgres_varchar255_max 255
  @postgres_varchar1000_max 1000
  @hours_per_day 24
  @minutes_per_hour 60
  @seconds_per_minute 60

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
  def moderate(%{id: user_id} = _user, post_attrs) do
    # query auto moderation rules from the db, check their validity then return them
    rule_actions = get_rule_actions(post_attrs)

    # append user_id to post attributes
    post_attrs = post_attrs |> Map.put("user_id", user_id)

    # execute rule actions if action set isn't empty, then return updated post_attributes
    post_attrs =
      if MapSet.size(rule_actions.action_set) > 0,
        do: execute_rule_actions(post_attrs, rule_actions),
        else: post_attrs

    # return updated post attributes
    post_attrs
  end

  ## === Private Helper Functions ===

  defp get_rule_actions(post_attrs) do
    acc_init = %{
      action_set: MapSet.new(),
      messages: [],
      ban_interval: nil,
      edits: []
    }

    rules = AutoModeration.all()

    Enum.reduce(rules, acc_init, fn rule, acc ->
      if rule_condition_is_valid?(post_attrs, rule.conditions) do
        # Aggregate all actions, using MapSet ensures actions are unique
        action_set = (MapSet.to_list(acc.action_set) ++ rule.actions) |> MapSet.new()

        # Aggregate all reject messages if applicable
        messages =
          if Enum.member?(rule.actions, "reject") and is_binary(rule.message),
            do: acc.messages ++ [rule.message],
            else: acc.messages

        # attempt to set default value for acc.ban_interval if nil
        acc =
          if is_nil(acc.ban_interval),
            do: Map.put(acc, :ban_interval, rule.options["ban_interval"]),
            else: acc

        # Pick the latest ban interval, in the event multiple are provided
        ban_interval =
          if Enum.member?(rule.actions, "ban") and
               Map.has_key?(rule.options, "ban_interval") and
               acc.ban_interval < rule.options["ban_interval"],
             do: rule.options["ban_interval"],
             else: acc.ban_interval

        # Aggregate all edit options
        edits =
          if Enum.member?(rule.actions, "edit"),
            do: acc.edits ++ [rule.options["edit"]],
            else: acc.edits

        # return updated acc
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
  end

  defp execute_rule_actions(
         post_attrs,
         %{
           action_set: action_set,
           messages: messages,
           ban_interval: ban_interval,
           edits: edits
         } = _rule_actions
       ) do
    # handle rule actions that edit the post body
    post_attrs =
      if MapSet.member?(action_set, "edit"),
        do:
          Enum.reduce(edits, post_attrs, fn edit, acc ->
            post_body = acc["body"]

            # handle actions that replace text in post body
            acc =
              if is_map(edit["replace"]) do
                replacement_text = edit["replace"]["text"]
                test_pattern = edit["replace"]["regex"]["pattern"]
                test_flags = edit["replace"]["regex"]["flags"]

                # compensate for elixir not supporting /g/ flag
                replace_globally = String.contains?(test_flags, "g")

                # remove g flag (doesnt work in elixir), compensate later using string replace
                test_flags = Regex.replace(~r/g/, test_flags, "")
                match_regex = Regex.compile!(test_pattern, test_flags)

                # update body of post with replacement text
                updated_post_body =
                  String.replace(post_body, match_regex, replacement_text,
                    global: replace_globally
                  )

                # return acc with updated post body
                Map.put(acc, "body", updated_post_body)
              else
                acc
              end

            # handle actions that replace post body using a template
            acc =
              if is_binary(edit["template"]) do
                # get new post body template
                template = edit["template"]

                # update post body using template
                updated_post_body = String.replace(template, "{body}", post_body)

                # return post_attrs with updated post body
                Map.put(acc, "body", updated_post_body)
              else
                acc
              end

            # return updated acc
            acc
          end),
        else: post_attrs

    # handle rule actions that ban the user
    if MapSet.member?(action_set, "ban") do
      # ban period is utc now plus how ever many days ban_interval is
      ban_period =
        if ban_interval,
          do:
            DateTime.utc_now()
            |> DateTime.add(ban_interval * @hours_per_day * @minutes_per_hour * @seconds_per_minute, :second)
            |> DateTime.to_naive()

      # get user_id from post_attrs
      user_id = post_attrs["user_id"]

      # ban the user, ban_period is either a date or nil (permanent)
      Ban.ban_by_user_id(user_id, ban_period)

      # update user session after banning
      Session.update(user_id)

      # send websocket notification to reauthenticate user
      EpochtalkServerWeb.Endpoint.broadcast("user:#{user_id}", "reauthenticate", %{})
    end

    # handle rule actions that shadow delete the post (auto lock/delete)
    post_attrs =
      if MapSet.member?(action_set, "delete"),
        do: post_attrs |> Map.put("deleted", true) |> Map.put("locked", true),
        else: post_attrs

    # handle rule actions that reject the post entirely
    if MapSet.member?(action_set, "reject"),
      do:
        raise(AutoModeratorReject,
          message: "Post rejected by Auto Moderator: #{Enum.join(messages, ", ")}"
        )

    post_attrs
  end

  defp rule_condition_is_valid?(post_attrs, conditions) do
    matches =
      Enum.map(conditions, fn condition ->
        test_param = post_attrs[condition["param"]]
        test_pattern = condition["regex"]["pattern"]
        test_flags = condition["regex"]["flags"]
        # remove g flag, one match is good enough to determine if condition is valid
        test_flags = Regex.replace(~r/g/, test_flags, "")
        match_regex = Regex.compile!(test_pattern, test_flags)
        Regex.match?(match_regex, test_param)
      end)

    # Only valid if every condition returns a valid regex match
    !Enum.member?(matches, false)
  end
end
