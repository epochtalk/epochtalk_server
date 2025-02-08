defmodule EpochtalkServer.Cache.ParsedPosts do
  use GenServer
  require Logger

  @table_name :parsed_posts

  @moduledoc """
  `ParsedPosts` cache genserver, used to cache parsed post data in a table in ETS
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(@table_name, key) do
      [{_, cached_value}] -> {:reply, {:ok, cached_value}, state}
      [] -> {:reply, {:error, []}, state}
    end
  end

  def handle_call({:insert, key, new_value}, _from, state) do
    case :ets.lookup(@table_name, key) do
      [] ->
        IO.inspect("#{key} inserting new value")
        :ets.insert_new(@table_name, {key, new_value})
        {:reply, {:ok, new_value}, state}

      [_, cached_value] ->
        if cached_value.updated_at < new_value.updated_at do
          IO.inspect("#{key} updating value")
          :ets.insert(@table_name, new_value)
          {:reply, {:ok, cached_value}, state}
        else
          IO.inspect("#{key} value not updated")
          {:reply, {:error, "value not updated"}, state}
        end
    end
  end

  def handle_call({:delete, key}, _from, state) do
    :ets.delete(@table_name, key)
    {:reply, :ok, state}
  end

  def handle_call({:exists_and_is_newer, key, new_value}, _from, state) do
    case :ets.lookup(@table_name, key) do
      [{_, cached_value}] ->
        if cached_value.updated_at < new_value.updated_at or cached_value.updated_at == new_value.updated_at do
          IO.inspect("#{key} value is newer or the same")
          {:reply, true, state}
        else
          IO.inspect("#{key} value is not newer")
          {:reply, false, state}
        end
      [] -> {:reply, false, state}
    end
  end

  ## === api functions ====

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def insert(key, new_value) do
    GenServer.call(__MODULE__, {:insert, key, new_value})
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def exists_and_is_newer(key, new_value) do
    GenServer.call(__MODULE__, {:exists_and_is_newer, key, new_value})
  end

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## === private functions ====

  # setup ETS table
  defp load() do
    :ets.new(@table_name, [:named_table, :public, :set])
    {:ok, %{}}
  end
end
