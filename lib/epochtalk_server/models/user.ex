defmodule EpochtalkServer.Models.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Profile
  alias EpochtalkServer.Models.Preference
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Models.BannedAddress
  alias EpochtalkServer.Models.BoardModerator
  alias EpochtalkServer.Models.Ban

  @moduledoc """
  `User` model, for performing actions relating a user
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          email: String.t() | nil,
          username: String.t() | nil,
          password: String.t() | nil,
          password_confirmation: String.t() | nil,
          passhash: String.t() | nil,
          confirmation_token: String.t() | nil,
          reset_token: String.t() | nil,
          reset_expiration: String.t() | nil,
          deleted: boolean | nil,
          malicious_score: float | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil,
          preferences: Preference.t() | term(),
          profile: Profile.t() | term(),
          ban_info: Ban.t() | term(),
          roles: [Role.t()] | term(),
          moderating: [BoardModerator.t()] | term()
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :email,
             :username,
             :deleted,
             :malicious_score,
             :preferences,
             :profile,
             :ban_info,
             :roles,
             :moderating,
             :created_at,
             :imported_at,
             :updated_at
           ]}
  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :passhash, :string
    field :confirmation_token, :string
    field :reset_token, :string
    field :reset_expiration, :string
    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :deleted, :boolean, default: false
    field :malicious_score, :decimal
    field :smf_member, :map, virtual: true

    # relation fields
    has_one :preferences, Preference
    has_one :profile, Profile
    has_one :ban_info, Ban
    many_to_many :roles, Role, join_through: RoleUser
    has_many :moderating, BoardModerator
  end

  ## === Changesets Functions ===

  @doc """
  Creates a registration changeset for `User` model, returns an error changeset
  if validation of username, email and password do not pass.
  """
  @spec registration_changeset(user :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :id,
      :email,
      :confirmation_token,
      :username,
      :created_at,
      :updated_at,
      :deleted,
      :malicious_score,
      :password
    ])
    |> unique_constraint(:id, name: :users_pkey)
    |> validate_username()
    |> validate_email()
    |> validate_password()
  end

  ## === Database Functions ===

  @doc """
  Creates a new `User` in the database, used for registration
  """
  @spec create(attrs :: map()) :: {:ok, user :: t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    user_cs = User.registration_changeset(%User{}, attrs)

    case Repo.insert(user_cs) do
      {:ok, user} ->
        # create Profile model for new User
        Profile.create(user.id)
        # preload associations, handle empty role, return user
        user =
          user
          # load associations
          |> Repo.preload([:preferences, :profile, :ban_info, :moderating])
          # appends default role
          |> Role.handle_empty_user_roles()

        {:ok, user}

      # changeset error
      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Creates a new `User` in the database and assigns the `superAdministrator` `Role`, used for seeding
  """
  @spec create(attrs :: map(), admin :: boolean) ::
          {:ok, user :: t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, true = _admin) do
    Repo.transaction(fn ->
      {:ok, user} = create(attrs)
      RoleUser.set_admin(user.id)
    end)
  end

  @doc """
  Checks if `User` with `username` exists in the database
  """
  @spec with_username_exists?(username :: String.t()) :: true | false
  def with_username_exists?(username),
    do: Repo.exists?(from u in User, where: u.username == ^username)

  @doc """
  Checks if `User` with `email` exists in the database
  """
  @spec with_email_exists?(email :: String.t()) :: true | false
  def with_email_exists?(email), do: Repo.exists?(from u in User, where: u.email == ^email)

  @doc """
  Gets a `User` from the database by `id`
  """
  @spec by_id(id :: integer) :: t() | nil
  def by_id(id) when is_integer(id), do: Repo.get_by(User, id: id)

  @doc """
  Gets `id` of `DefaultTrustList` `User` from the database
  """
  @spec get_default_trust_user_id() :: non_neg_integer | nil
  def get_default_trust_user_id() do
    query = from u in User,
      where: u.username == "DefaultTrustList",
      select: u.id
    Repo.one(query)
  end

  @doc """
  Clears the malicious score of a `User` by `id`, from the database
  """
  @spec clear_malicious_score_by_id(id :: integer) :: {non_neg_integer(), nil}
  def clear_malicious_score_by_id(id), do: set_malicious_score_by_id(id, nil)

  @doc """
  Gets a `User` by `username`, from the database, with all of it's associations preloaded.
  Appends the `user` `Role` to `user.roles` if no roles present. Strips all roles but
  `banned` from `user.roles` if user is banned.
  """
  @spec by_username(username :: String.t()) :: {:ok, user :: t()} | {:error, :user_not_found}
  def by_username(username) when is_binary(username) do
    query =
      from u in User,
        where: u.username == ^username,
        preload: [:preferences, :profile, :ban_info, :moderating, :roles]

    if user = Repo.one(query),
      do: {:ok, user |> Role.handle_empty_user_roles() |> Role.handle_banned_user_role()},
      else: {:error, :user_not_found}
  end

  @doc """
  Checks if the provided `User` is malicious using the provided `ip`. If the `User`
  is found to be malicious after checking `BannedAddress` records, the user's
  `malicious_score` is updated and is assigned the `banned` `Role`, in the database
  and in place. Otherwise the user is just returned with no change.
  """
  @spec handle_malicious_user(user :: t(), ip :: tuple) ::
          {:ok, user :: t()} | {:error, :ban_error}
  def handle_malicious_user(%User{} = user, ip) do
    # convert ip tuple into string
    ip_str = ip |> :inet_parse.ntoa() |> to_string
    # calculate user's malicious score from ip, nil if less than 1
    malicious_score = BannedAddress.calculate_malicious_score_from_ip(ip_str)
    # set user's malicious score
    user = set_malicious_score(user, malicious_score)
    # if user's malicious score is 1 or more ban the user, update roles and ban info
    if is_nil(user.malicious_score) || user.malicious_score < 1,
      do: {:ok, user},
      else: Ban.ban(user)
  end

  ## === Helper Functions ===

  @doc """
  Validates with Argon2 that a `User` `passhash` matches the supplied `password`
  """
  @spec valid_password?(user :: t(), password :: String.t()) :: true | false
  def valid_password?(%User{passhash: hashed_password} = _user, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  ## === Private Helper Functions ===
  # sets malicious score of a user, outputs user with updated malicious score
  defp set_malicious_score(%User{id: id} = user, malicious_score) do
    set_malicious_score_by_id(id, malicious_score)

    if malicious_score != nil,
      do: user |> Map.put(:malicious_score, malicious_score),
      else: user
  end

  # sets malicious score of a user
  defp set_malicious_score_by_id(id, malicious_score) do
    from(u in User, where: u.id == ^id)
    |> Repo.update_all(set: [malicious_score: malicious_score])
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required(:username)
    |> validate_length(:username, min: 3, max: 255)
    |> unique_constraint(:username)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    # check that password matches password_confirmation
    #   checks that password and password_confirmation match
    #   but does not require password_confirmation to be supplied
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_length(:password, min: 8, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> hash_password()
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:passhash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
