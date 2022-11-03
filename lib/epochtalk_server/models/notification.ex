defmodule EpochtalkServer.Models.Notification do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Notification
  alias EpochtalkServer.Models.User
  @max_count 99
  @types %{
    message: "message",
    mention: "mention"
  }

  @moduledoc """
  `Notification` model, for performing actions relating to forum categories
  """
  @type t :: %__MODULE__{
    id: non_neg_integer | nil,
    sender_id: non_neg_integer | nil,
    receiver_id: non_neg_integer | nil,
    data: map() | nil,
    viewed: boolean | nil,
    type: String.t() | nil,
    created_at: NaiveDateTime.t() | nil
  }
  schema "notifications" do
    belongs_to :sender, User
    belongs_to :receiver, User
    field :data, :map
    field :viewed, :boolean
    field :type, :string
    field :created_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Notification` model
  """
  @spec changeset(notification :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:id, :sender_id, :receiver_id, :data, :viewed, :type, :created_at])
    |> unique_constraint(:id, name: :notifications_pkey)
  end

  @doc """
  Returns `Notification` counts for a specific `User` by `id`, from the database. Used
  to display new message/mention notifications.
  """
  @spec counts_by_user_id(user_id :: integer) :: map()
  def counts_by_user_id(user_id) when is_integer(user_id) do
    query = from n in Notification,
      where: n.receiver_id == ^user_id and n.viewed == false,
      limit: @max_count + 1
    query
    |> Repo.one()
    |> case do
      nil -> %{ message: 0, mentions: 0 }
      notifications ->
        {messages, mentions} = Enum.split_with(notifications, &(&1.type == @types.message))
        %{
          message: (if (count = length(messages)) > @max_count, do: "#{@max_count}+", else: count),
          mention: (if (count = length(mentions)) > @max_count, do: "#{@max_count}+", else: count)
        }
    end
  end

  @doc """
  Dismisses `Notification` counts for a specific `User` by `id`. Used
  to display clear message/mention notifications.
  """
  @spec dismiss_type_by_user_id(user_id :: integer, type :: String.t()) :: {non_neg_integer, nil | [term()]} | {:error, :invalid_notification_type}
  def dismiss_type_by_user_id(user_id, type) when is_integer(user_id) do
    if valid_type(type) do
      query = from n in Notification,
        where: n.receiver_id == ^user_id and n.viewed == false and n.type == ^type
      Repo.update_all(query, set: [viewed: true])
    else
      {:error, :invalid_notification_type}
    end
  end

  @doc """
  Dismisses specific `Notification` by `id`. Used
  to display clear a specific message/mention `Notification`.
  """
  @spec dismiss(id :: integer) :: {non_neg_integer, nil | [term()]}
  def dismiss(id) when is_integer(id) do
    query = from n in Notification, where: n.id == ^id
    Repo.update_all(query, set: [viewed: true])
  end

  defp valid_type(type), do: Map.has_key?(@types, String.to_atom(type))
end
