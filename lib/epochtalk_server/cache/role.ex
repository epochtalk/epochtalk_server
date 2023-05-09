defmodule EpochtalkServer.Cache.Role do
  use GenServer
  use Ecto.Schema
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Role

  @impl true
  def init(:ok) do
    # TODO(boka): don't need to use role_cache
    role_cache = load()
    {:ok, role_cache}
  end

  @impl true
  def handle_call({:lookup, lookups}, _from, role_cache) when is_list(lookups) do
    {:reply, Map.take(role_cache, lookups) |> Enum.map(fn {_k, v} -> v end) |> Enum.sort(&(&1.id < &2.id)), role_cache}
  end

  @impl true
  def handle_call({:lookup, lookup}, _from, role_cache) do
    {:reply, Map.get(role_cache, lookup), role_cache}
  end

  @impl true
  def handle_cast(:reload, _role_cache) do
    role_cache = load()
    {:noreply, role_cache}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def by_lookup(lookup_or_lookups) do
    GenServer.call(__MODULE__, {:lookup, lookup_or_lookups})
  end

  # reloads role cache
  def reload() do
    GenServer.cast(__MODULE__, :reload)
  end

  # returns loaded role cache
  defp load() do
    Role |> Repo.all() |> Enum.reduce( %{}, fn role, role_cache -> role_cache |> Map.put(role.lookup, role) end)
  end
end
