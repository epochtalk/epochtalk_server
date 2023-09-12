defmodule EpochtalkServer.Models.ThreadSubscription do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.ThreadSubscription
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Preference
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Mailer

  @moduledoc """
  `ThreadSubscription` model, for performing actions relating to `ThreadSubscription`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          thread_id: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:user_id, :thread_id]}
  @primary_key false
  @schema_prefix "users"
  schema "thread_subscriptions" do
    field :user_id, :integer
    field :thread_id, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for `ThreadSubscription` model
  """
  @spec create_changeset(
          thread_subscription :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(thread_subscription, attrs \\ %{}) do
    thread_subscription
    |> cast(attrs, [:user_id, :thread_id])
    |> validate_required([:user_id, :thread_id])
    |> unique_constraint([:user_id, :thread_id],
      name: :thread_subscriptions_user_id_thread_id_index
    )

    # TODO(akinsey): migration is missing these foreign key constraints, this 
    # wont cause any errors, but they should be there for correctness
    # |> foreign_key_constraint(:thread_id, name: :thread_subscriptions_thread_id_fkey)
    # |> foreign_key_constraint(:user_id, name: :thread_subscriptions_user_id_fkey)
  end

  ## === Database Functions ===

  @doc """
  Create `ThreadSubscription` in the database. First checks if the `User` has `Preference` `notify_replied_threads` set.
  """
  @spec create(user :: User.t(), thread_id :: non_neg_integer) ::
          {:ok, thread_subscription :: t()} | {:error, Ecto.Changeset.t()} | nil
  def create(%{} = user, thread_id) do
    if Preference.notify_replied_threads?(user.id) do
      thread_subscription_cs =
        create_changeset(%ThreadSubscription{user_id: user.id, thread_id: thread_id})

      Repo.insert(thread_subscription_cs)
    end
  end

  @doc """
  Deletes a specific `ThreadSubscription` record from the database.
  """
  @spec delete(user :: User.t(), thread_id :: non_neg_integer) ::
          {non_neg_integer(), nil | [term()]}
  def delete(%{} = user, thread_id) do
    query =
      from t in ThreadSubscription,
        where: t.user_id == ^user.id and t.thread_id == ^thread_id

    Repo.delete_all(query)
  end

  @doc """
  Deletes all `ThreadSubscription` records for a specific `User` from the database.
  """
  @spec delete_all(user :: User.t()) ::
          {non_neg_integer(), nil | [term()]}
  def delete_all(%{} = user) do
    query =
      from t in ThreadSubscription,
        where: t.user_id == ^user.id

    Repo.delete_all(query)
  end

  @doc """
  Get all `Thread` subscriber's `User` data for emailing
  """
  @spec get_subscriber_email_data(user :: User.t(), thread_id :: non_neg_integer) ::
          {:ok, thread_subscription :: t()} | {:error, Ecto.Changeset.t()}
  def get_subscriber_email_data(%{} = user, thread_id) do
    inner_thread_subscription_query =
      from t in ThreadSubscription,
        where: t.thread_id == ^thread_id and t.user_id != ^user.id,
        select: t.user_id

    query =
      from u in User,
        where: u.id in subquery(inner_thread_subscription_query),
        select: %{
          user_id: u.id,
          email: u.email,
          username: u.username,
          thread_slug:
            subquery(
              from t in Thread,
                where: t.id == ^thread_id,
                select: t.slug
            ),
          id:
            subquery(
              from p in Post,
                where: p.thread_id == ^thread_id,
                select: p.id,
                order_by: [desc: p.created_at],
                limit: 1
            ),
          position:
            subquery(
              from p in Post,
                where: p.thread_id == ^thread_id,
                select: p.position,
                order_by: [desc: p.created_at],
                limit: 1
            ),
          thread_author:
            subquery(
              from p in Post,
                where: p.thread_id == ^thread_id,
                select: p.user_id,
                order_by: [desc: p.created_at],
                limit: 1
            ) == u.id,
          title:
            subquery(
              from p in Post,
                where: p.thread_id == ^thread_id,
                select: p.content["title"],
                order_by: [desc: p.created_at],
                limit: 1
            )
        }

    Repo.all(query)
  end

  # === Public Helper Functions ===

  @doc """
  Emails all subscribers of a particular `Thread` when there are new replies
  """
  @spec email_subscribers(user :: map, thread_id :: non_neg_integer) :: :ok
  def email_subscribers(%{} = user, thread_id) do
    get_subscriber_email_data(user, thread_id)
    |> Enum.each(fn email_data ->
      Mailer.send_thread_subscription(email_data)
      if email_data.thread_author == false, do: delete(user, thread_id)
    end)
  end
end
