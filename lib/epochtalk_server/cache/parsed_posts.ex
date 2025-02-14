defmodule EpochtalkServer.Cache.ParsedPosts do
  use GenServer
  require Logger
  import Ex2ms

  @table_name :parsed_posts
  @max_size 10_000
  @purge_size 1000
  @expiry_days 30

  @moduledoc """
  `ParsedPosts` cache genserver, used to cache parsed post data in a table in ETS
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, setup()}

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(@table_name, key) do
      [{_key, cached_value, _expires}] -> {:reply, {:ok, cached_value}, state}
      [] -> {:reply, {:error, []}, state}
    end
  end

  @impl true
  def handle_call({:put, key, new_value}, _from, state) do
    expires = DateTime.add(DateTime.utc_now(), @expiry_days, :day) |> DateTime.to_unix()
    :ets.insert(@table_name, {key, new_value, expires})
    {:reply, {:ok, new_value}, state}
  end

  @impl true
  def handle_call({:need_update, key, new_value}, _from, state) do
    case :ets.lookup(@table_name, key) do
      [{_key, cached_value, _expires}] ->
        if cached_value.updated_at < new_value.updated_at do
          # new_value was updated since it was cached, needs to be parsed
          {:reply, true, state}
        else
          # new_value is not updated, use cached value
          {:reply, false, state}
        end

      # key not found in cache, needs to be parsed
      [] ->
        {:reply, true, state}
    end
  end

  @impl true
  def handle_call(:lookup_and_purge, _from, state) do
    # if table size is greater than max size, purge
    if :ets.info(@table_name, :size) > @max_size do
      purge()
      {:reply, true, state}
    end

    {:reply, false, state}
  end

  ## === cache api functions ====

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, new_value) do
    GenServer.call(__MODULE__, {:put, key, new_value})
  end

  def need_update(key, new_value) do
    GenServer.call(__MODULE__, {:need_update, key, new_value})
  end

  def lookup_and_purge() do
    GenServer.call(__MODULE__, :lookup_and_purge)
  end

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## === private functions ====

  # setup ETS table
  defp setup() do
    :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  defp purge() do
    # keep table fixated while purging
    :ets.safe_fixtable(@table_name, true)
    do_purge()
  after
    :ets.safe_fixtable(@table_name, false)
  end

  defp do_purge() do
    count = 0
    now = DateTime.utc_now() |> DateTime.to_unix()
    # select keys that have expired
    case :ets.select(
           @table_name,
           fun do
             {key, _, expires} when ^now > expires -> key
           end
         ) do
      [] ->
        # if no keys have expired, purge from first key in the table
        purge_from_first(:ets.first(@table_name), count)

      keys ->
        # if keys have expired, delete them
        Enum.each(keys, fn key -> :ets.delete(@table_name, key) end)
    end
  end

  defp purge_from_first(_, @purge_size), do: :ok

  defp purge_from_first(:"$end_of_table", _), do: :ok

  defp purge_from_first(key, count) do
    :ets.delete(@table_name, key)
    purge_from_first(:ets.next(@table_name, key), count + 1)
  end
end
