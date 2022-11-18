defmodule EpochtalkServer.Models.BannedAddress do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.BannedAddress

  @moduledoc """
  `BannedAddress` model, for performing actions relating to banning by ip/hostname
  """
  @type t :: %__MODULE__{
          hostname: String.t() | nil,
          ip1: non_neg_integer | nil,
          ip2: non_neg_integer | nil,
          ip3: non_neg_integer | nil,
          ip4: non_neg_integer | nil,
          weight: float | nil,
          decay: boolean | nil,
          created_at: NaiveDateTime.t() | nil,
          imported_at: NaiveDateTime.t() | nil,
          updates: [NaiveDateTime.t()] | nil
        }
  @primary_key false
  schema "banned_addresses" do
    field :hostname, :string
    field :ip1, :integer
    field :ip2, :integer
    field :ip3, :integer
    field :ip4, :integer
    field :weight, :decimal
    field :decay, :boolean, default: false
    field :imported_at, :naive_datetime
    field :created_at, :naive_datetime
    field :updates, {:array, :naive_datetime}
  end

  ## === Changesets Functions ===

  @doc """
  Creates changeset for upsert of `BannedAddress` model
  """
  @spec upsert_changeset(banned_address :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def upsert_changeset(banned_address, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    attrs =
      attrs
      |> Map.put(:created_at, now)
      # default false
      |> Map.put(:decay, if(decay = Map.get(attrs, :decay), do: decay, else: false))
      |> Map.put(
        :updates,
        if(updates = Map.get(banned_address, :updates), do: updates ++ [now], else: [])
      )

    case Map.get(attrs, :hostname) do
      nil ->
        ip = String.split(attrs.ip, ".")

        attrs =
          attrs
          |> Map.put(:ip1, Enum.at(ip, 0))
          |> Map.put(:ip2, Enum.at(ip, 1))
          |> Map.put(:ip3, Enum.at(ip, 2))
          |> Map.put(:ip4, Enum.at(ip, 3))

        ip_changeset(banned_address, attrs)

      _ ->
        hostname_changeset(banned_address, attrs)
    end
  end

  @doc """
  Creates changeset of `BannedAddress` model with hostname information
  """
  @spec hostname_changeset(banned_address :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def hostname_changeset(banned_address, attrs \\ %{}) do
    banned_address
    |> cast(attrs, [:hostname, :weight, :decay, :imported_at, :created_at, :updates])
    |> validate_required([:hostname, :weight, :decay, :created_at, :updates])
    |> unique_constraint(:hostname, name: :banned_addresses_hostname_index)
  end

  @doc """
  Creates changeset of `BannedAddress` model with IP information
  """
  @spec ip_changeset(banned_address :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def ip_changeset(banned_address, attrs \\ %{}) do
    cs_data =
      banned_address
      |> cast(attrs, [
        :ip1,
        :ip2,
        :ip3,
        :ip4,
        :weight,
        :decay,
        :imported_at,
        :created_at,
        :updates
      ])
      |> validate_required([:ip1, :ip2, :ip3, :ip4, :weight, :decay, :created_at, :updates])
      |> unique_constraint([:ip1, :ip2, :ip3, :ip4], name: :banned_addresses_unique_ip_constraint)

    # have changeset calculate new decayed weight if necessary
    updated_cs = Map.merge(cs_data.data, cs_data.changes)

    case Map.get(banned_address, :decay) and updated_cs.decay do
      # get existing decayed weight since ip was last seen
      true ->
        weight = calculate_score_decay(banned_address)
        # since this ip has been previously banned run through algorithm
        # min(2 * old_score, old_score + 1000) to get new weight where
        # old_score accounts for previous decay
        weight = min(2 * weight, weight + 1000)
        change(cs_data, %{weight: weight})

      false ->
        cs_data
    end
  end

  ## === Database Functions ===

  @doc """
  Upserts a `BannedAddress` into the database and handles calculation of weight accounting for decay
  """
  @spec upsert(banned_address_or_list :: map() | [map()] | t() | [t()]) ::
          {:ok, banned_address_changeset :: Ecto.Changeset.t()} | {:error, :banned_address_error}
  def upsert(address_list) when is_list(address_list) do
    Repo.transaction(fn -> Enum.each(address_list, &upsert_one(&1)) end)
    |> case do
      {:ok, banned_address_changeset} ->
        {:ok, banned_address_changeset}

      # print error, return error atom
      {:error, err} ->
        # TODO(akinsey): handle in logger (telemetry possibly)
        Logger.error(inspect(err))
        {:error, :banned_address_error}
    end
  end

  def upsert(banned_address), do: upsert([banned_address])

  defp upsert_one(banned_address) do
    case Map.get(banned_address, :hostname) do
      # IP type banned address
      nil ->
        ip = String.split(banned_address.ip, ".")
        ip1 = Enum.at(ip, 0)
        ip2 = Enum.at(ip, 1)
        ip3 = Enum.at(ip, 2)
        ip4 = Enum.at(ip, 3)
        db_banned_address = Repo.get_by(BannedAddress, %{ip1: ip1, ip2: ip2, ip3: ip3, ip4: ip4})
        # update
        # insert
        if db_banned_address do
          cs_data = upsert_changeset(db_banned_address, banned_address)
          updated_cs = Map.merge(cs_data.data, cs_data.changes)

          from(ba in BannedAddress,
            where: ba.ip1 == ^ip1 and ba.ip2 == ^ip2 and ba.ip3 == ^ip3 and ba.ip4 == ^ip4
          )
          |> Repo.update_all(
            set: [
              weight: Map.get(updated_cs, :weight),
              decay: Map.get(updated_cs, :decay),
              updates: Map.get(updated_cs, :updates)
            ]
          )

          {:ok, updated_cs}
        else
          Repo.insert(upsert_changeset(%BannedAddress{}, banned_address), returning: true)
        end

      # hostname type banned address
      hostname ->
        # update
        # insert
        if db_banned_address = Repo.get_by(BannedAddress, hostname: hostname) do
          # grab changes from changeset, this is a workaround since
          # we can't use Repo.update, because there is no primary key
          cs_data = upsert_changeset(db_banned_address, banned_address)
          updated_cs = Map.merge(cs_data.data, cs_data.changes)

          from(ba in BannedAddress, where: ba.hostname == ^hostname)
          |> Repo.update_all(
            set: [
              weight: Map.get(updated_cs, :weight),
              decay: Map.get(updated_cs, :decay),
              updates: Map.get(updated_cs, :updates)
            ]
          )

          {:ok, updated_cs}
        else
          Repo.insert(upsert_changeset(%BannedAddress{}, banned_address), returning: true)
        end
    end
  end

  ## === External Helper Functions ===

  @doc """
  Calculates the malicious score of the provided IP address, `float` score is returned if IP/Hostname are malicious, otherwise nil
  """
  @spec calculate_malicious_score_from_ip(ip_address :: String.t()) :: float | nil
  def calculate_malicious_score_from_ip(ip) when is_binary(ip) do
    case :inet.parse_address(to_charlist(ip)) do
      {:ok, ip} ->
        hostname_score =
          case :inet.gethostbyaddr(ip) do
            {:ok, host} ->
              hostname_from_host(host) |> calculate_hostname_score

            # no hostname found, return nil for hostname score
            {:error, _} ->
              0
          end

        ip32_score = calculate_ip32_score(ip)
        ip24_score = calculate_ip24_score(ip)
        ip16_score = calculate_ip16_score(ip)
        # calculate malicious score using all scores
        malicious_score = hostname_score + ip32_score + 0.04 + ip24_score + 0.0016 + ip16_score
        if malicious_score < 1, do: nil, else: malicious_score

      # invalid ip address, return nil for malicious score
      {:error, _} ->
        nil
    end
  end

  ## === Private Helper Functions ===

  defp hostname_from_host({_, name, _, _, _, _}), do: List.to_string(name)

  defp calculate_hostname_score(hostname) do
    from(ba in BannedAddress,
      where: like(ba.hostname, ^hostname),
      select: %{
        weight: ba.weight,
        decay: ba.decay,
        created_at: ba.created_at,
        updates: ba.updates
      }
    )
    |> Repo.one()
    |> calculate_score_decay
  end

  defp calculate_ip32_score({ip1, ip2, ip3, ip4}) do
    from(ba in BannedAddress,
      where: ba.ip1 == ^ip1 and ba.ip2 == ^ip2 and ba.ip3 == ^ip3 and ba.ip4 == ^ip4,
      select: %{
        weight: ba.weight,
        decay: ba.decay,
        created_at: ba.created_at,
        updates: ba.updates
      }
    )
    |> Repo.one()
    |> calculate_score_decay
  end

  defp calculate_ip24_score({ip1, ip2, ip3, _}) do
    from(ba in BannedAddress,
      where: ba.ip1 == ^ip1 and ba.ip2 == ^ip2 and ba.ip3 == ^ip3,
      select: %{
        weight: ba.weight,
        decay: ba.decay,
        created_at: ba.created_at,
        updates: ba.updates
      }
    )
    |> Repo.one()
    |> calculate_score_decay
  end

  defp calculate_ip16_score({ip1, ip2, _, _}) do
    from(ba in BannedAddress,
      where: ba.ip1 == ^ip1 and ba.ip2 == ^ip2,
      select: %{
        weight: ba.weight,
        decay: ba.decay,
        created_at: ba.created_at,
        updates: ba.updates
      }
    )
    |> Repo.one()
    |> calculate_score_decay
  end

  # Calculates decay given MS and a weight
  # Decay algorithm is 0.8897*curWeight^0.9644 run weekly
  # This will calculate decay given the amount of time that has passed
  # in ms since the weight was last updated
  defp decay_for_time(time, weight) do
    weight = Decimal.to_float(weight)
    one_week = 1000 * 60 * 60 * 24 * 7
    weeks = time / one_week
    a = 0.8897
    r = 0.9644
    a ** ((r ** weeks - 1) / (r - 1)) * weight ** (r ** weeks)
  end

  # returns the decayed score given a banned address
  # no banned address data found return 0
  defp calculate_score_decay(nil), do: 0
  defp calculate_score_decay(banned_address) when banned_address == %{}, do: 0
  defp calculate_score_decay(banned_address) when is_nil(banned_address), do: 0
  # banned address data found and decays, calculate
  defp calculate_score_decay(
         %{decay: true, updates: updates, weight: weight, created_at: created_at} =
           _banned_address
       ) do
    last_update_date = if length(updates) > 0, do: List.last(updates), else: created_at
    diff_ms = abs(NaiveDateTime.diff(last_update_date, NaiveDateTime.utc_now()) * 1000)
    decay_for_time(diff_ms, weight)
  end

  # banned address data found, but does not decay
  defp calculate_score_decay(banned_address), do: Decimal.to_float(banned_address.weight)
end
