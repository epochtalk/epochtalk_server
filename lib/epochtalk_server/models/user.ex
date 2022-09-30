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
    has_many :roles, RoleUser
    has_many :moderating, BoardModerator
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :email, :username, :created_at, :updated_at, :deleted, :malicious_score, :password])
    |> unique_constraint(:id, name: :users_pkey)
    |> validate_username()
    |> validate_email()
    |> validate_password()
  end
  # create admin, for seeding
  def create(attrs, true = _admin) do
    Repo.transaction(fn ->
      create(attrs)
      |> case do {:ok, %{ id: id } = _user} -> RoleUser.set_admin(id) end
    end)
  end
  def create(attrs) do
    user_cs = User.registration_changeset(%User{}, attrs)
    case Repo.insert(user_cs) do
      {:ok, user} -> {:ok, user |> Map.put(:roles, Role.by_user_id(user.id))} # append roles
      {:error, err} -> {:error, err}
    end
  end

  def with_username_exists?(username), do: Repo.exists?(from u in User, where: u.username == ^username)

  def with_email_exists?(email), do: Repo.exists?(from u in User, where: u.email == ^email)

  def by_id(id) when is_integer(id), do: Repo.get_by(User, id: id)

  defp set_malicious_score(%User{ id: id } = user, malicious_score) do
    from(u in User, where: u.id == ^id)
    |> Repo.update_all(set: [malicious_score: malicious_score])
    if malicious_score != nil && malicious_score >= 1,
      do: user |> Map.put(:malicious_score, malicious_score),
      else: user
  end

  def clear_malicious_score(%User{} = user), do: set_malicious_score(user, nil)

  def handle_malicious_user(%User{} = user, ip) do
    # convert ip tuple into string
    ip_str = ip |> :inet_parse.ntoa |> to_string
    # calculate user's malicious score from ip
    malicious_score = BannedAddress.calculate_malicious_score_from_ip(ip_str)
    # set user's malicious score
    user = set_malicious_score(user, malicious_score)
    # if user's malicious score is 1 or more ban the user, update roles and ban info
    user = ban_if_malicious(user)
    user
  end

  defp ban_if_malicious(%User{ malicious_score: nil } = user), do: {:ok, user}
  defp ban_if_malicious(%User{ malicious_score: score } = user) when score < 1, do: {:ok, user}
  defp ban_if_malicious(%User{ malicious_score: score } = user) when score >= 1, do: Ban.ban(user)

  def by_username(username) when is_binary(username) do
    query = from u in User,
    left_join: p in Profile,
      on: u.id == p.user_id,
    left_join: pr in Preference,
      on: u.id == pr.user_id,
    select: %{
      id: u.id,
      username: u.username,
      email: u.email,
      passhash: u.passhash,
      confirmation_token: u.confirmation_token,
      reset_token: u.reset_token,
      reset_expiration: u.reset_expiration,
      deleted: u.deleted,
      malicious_score: u.malicious_score,
      created_at: u.created_at,
      updated_at: u.updated_at,
      imported_at: u.imported_at,
      avatar: p.avatar,
      position: p.position,
      signature: p.signature,
      raw_signature: p.raw_signature,
      fields: p.fields,
      post_count: p.post_count,
      last_active: p.last_active,
      posts_per_page: pr.posts_per_page,
      threads_per_page: pr.threads_per_page,
      collapsed_categories: pr.collapsed_categories,
      ignored_boards: pr.ignored_boards,
      ban_expiration: fragment("""
        CASE WHEN EXISTS (
          SELECT user_id
          FROM roles_users
          WHERE role_id = (SELECT id FROM roles WHERE lookup = \'banned\') and user_id = ?
        )
        THEN (
          SELECT expiration
          FROM users.bans
          WHERE user_id = ?
        )
        ELSE NULL END
      """, u.id, u.id)},
    where: u.username == ^username

    if user = Repo.one(query) do
      # set all user's roles
      user = Map.put(user, :roles, Role.by_user_id(user.id))
      # set primary role info
      primary_role = List.first(user[:roles])
      hc = Map.get(primary_role, :highlight_color)
      Map.put(user, :role_name, primary_role.name)
      |> Map.put(:role_highlight_color, (if hc, do: hc, else: ""))
      |> format_user
    end
  end
  def valid_password?(%{passhash: hashed_password} = _user, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
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
  defp format_user(user) do
    user = Map.filter(user, fn {_, v} -> v end) # remove nil
    user = if f = Map.get(user, :fields), do: Map.merge(user, f), else: user # merge fields onto user
    user = if cc = Map.get(user, :collapsed_categories), do: Map.put(user, :collapsed_categories, Map.get(cc, "cats")), else: user # unnest cats
    user = if ib = Map.get(user, :ignored_boards), do: Map.put(user, :ignored_boards, Map.get(ib, "boards")), else: user #unnest boards
    Map.delete(user, :fields) # strip fields from user
    |> Map.put(:avatar, Map.get(user, :avatar)) # sets avatar back to nil if not set
  end
end
