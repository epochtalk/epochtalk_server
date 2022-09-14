defmodule EpochtalkServer.Models.BannedAddress do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.BannedAddress

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

  def changeset(banned_address, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    attrs = attrs
    |> Map.put(:created_at, now)
    |> Map.put(:decay, (if decay = Map.get(attrs, :decay), do: decay, else: false)) # default false
    |> Map.put(:updates, (if updates = Map.get(banned_address, :updates), do: updates ++ [now], else: []))
    case Map.get(attrs, :hostname) do
      nil -> ip = String.split(attrs.ip, ".")
        attrs = attrs
        |> Map.put(:ip1, Enum.at(ip, 0))
        |> Map.put(:ip2, Enum.at(ip, 1))
        |> Map.put(:ip3, Enum.at(ip, 2))
        |> Map.put(:ip4, Enum.at(ip, 3))
        changeset_ip(banned_address, attrs)
      _   -> changeset_hostname(banned_address, attrs)
    end
  end
  def changeset_hostname(banned_address, attrs \\ %{}) do
    banned_address
    |> cast(attrs, [:hostname, :weight, :decay, :imported_at, :created_at, :updates])
    |> validate_required([:hostname, :weight, :decay, :created_at, :updates])
    |> unique_constraint(:hostname, name: :banned_addresses_hostname_index)
  end
  def changeset_ip(banned_address, attrs \\ %{}) do
    cs_data = banned_address
    |> cast(attrs, [:ip1, :ip2, :ip3, :ip4, :weight, :decay, :imported_at, :created_at, :updates])
    |> validate_required([:ip1, :ip2, :ip3, :ip4, :weight, :decay, :created_at, :updates])
    |> unique_constraint([:ip1, :ip2, :ip3, :ip4], name: :banned_addresses_unique_ip_constraint)
    # have changeset calculate new decayed weight if necessary
    updated_cs = Map.merge(cs_data.data, cs_data.changes)
    case Map.get(banned_address, :decay) and updated_cs.decay do
      true -> weight = calculate_score_decay(banned_address) # get existing decayed weight since ip was last seen
        # since this ip has been previously banned run through algorithm
        # min(2 * old_score, old_score + 1000) to get new weight where
        # old_score accounts for previous decay
        weight = min(2 * weight, weight + 1000)
        change(cs_data, %{ weight: weight })
      false -> cs_data
    end
  end

  def upsert(address_list) when is_list(address_list) do
    Repo.transaction(fn ->
      Enum.each(address_list ,&BannedAddress.upsert(&1))
    end)
  end
  def upsert(banned_address) do
    case Map.get(banned_address, :hostname) do
      # IP type banned address
      nil ->
        ip = String.split(banned_address.ip, ".")
        ip1 = Enum.at(ip, 0)
        ip2 = Enum.at(ip, 1)
        ip3 = Enum.at(ip, 2)
        ip4 = Enum.at(ip, 3)
        db_banned_address = Repo.get_by(BannedAddress, %{ip1: ip1, ip2: ip2, ip3: ip3, ip4: ip4})
        if db_banned_address do # update
          cs_data = changeset(db_banned_address, banned_address)
          updated_cs = Map.merge(cs_data.data, cs_data.changes)
          from(ba in BannedAddress, where: ba.ip1 == ^ip1 and ba.ip2 == ^ip2 and ba.ip3 == ^ip3 and ba.ip4 == ^ip4)
          |> Repo.update_all(set: [
            weight: Map.get(updated_cs, :weight),
            decay: Map.get(updated_cs, :decay),
            updates: Map.get(updated_cs, :updates)
          ])
          {:ok, updated_cs}
        else Repo.insert(changeset(%BannedAddress{}, banned_address), returning: true) end #insert
      # hostname type banned address
      hostname ->
        if db_banned_address = Repo.get_by(BannedAddress, hostname: hostname) do # update
          # grab changes from changeset, this is a workaround since
          # we can't use Repo.update, because there is no primary key
          cs_data = changeset(db_banned_address, banned_address)
          updated_cs = Map.merge(cs_data.data, cs_data.changes)
          from(ba in BannedAddress, where: ba.hostname == ^hostname)
          |> Repo.update_all(set: [
            weight: Map.get(updated_cs, :weight),
            decay: Map.get(updated_cs, :decay),
            updates: Map.get(updated_cs, :updates)
          ])
          {:ok, updated_cs}
        else Repo.insert(changeset(%BannedAddress{}, banned_address), returning: true) end # insert
    end
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
    (a ** (((r ** weeks) - 1) / (r - 1))) * (weight ** (r ** weeks))
  end

  # returns the decayed score given a banned address
  # no banned address data found return 0
  def calculate_score_decay(), do: 0
  def calculate_score_decay(banned_address) when banned_address == %{}, do: 0
  def calculate_score_decay(banned_address) when is_nil(banned_address), do: 0
  # banned address data found and decays, calculate
  def calculate_score_decay(%{ decay: true, updates: updates, weight: weight, created_at: created_at } = _banned_address) do
    last_update_date = if length(updates) > 0, do: List.last(updates), else: created_at
    diff_ms = abs(NaiveDateTime.diff(last_update_date, NaiveDateTime.utc_now()) * 1000)
    decay_for_time(diff_ms, weight)
  end
  # banned address data found, but does not decay
  def calculate_score_decay(banned_address), do: banned_address.weight
end
