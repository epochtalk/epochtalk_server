defmodule EpochtalkServer.Cache.Role do
  use GenServer
  use Ecto.Schema
  alias EpochtalkServer.Models.Role

  @moduledoc """
  `Role` cache genserver, stores roles in memory for quick lookup
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_call(:all, _from, {all_roles, lookup_cache}),
    do: {:reply, all_roles, {all_roles, lookup_cache}}

  @impl true
  def handle_call({:lookup, lookups}, _from, {all_roles, lookup_cache}) when is_list(lookups) do
    roles =
      Map.take(lookup_cache, lookups)
      |> Enum.map(fn {_k, v} -> v end)
      |> Enum.sort(&(&1.id < &2.id))

    {:reply, roles, {all_roles, lookup_cache}}
  end

  @impl true
  def handle_call({:lookup, lookup}, _from, {all_roles, lookup_cache}) do
    role = Map.get(lookup_cache, lookup)
    {:reply, role, {all_roles, lookup_cache}}
  end

  @impl true
  def handle_cast(:reload, {_all_roles, _lookup_cache}), do: {:noreply, load()}

  ## === cache api functions ====

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Returns all `Role`s
  """
  @spec all() :: [Role.t()]
  def all() do
    GenServer.call(__MODULE__, :all)
  end

  @doc """
  Returns a `Role` or list of `Role`s for specified lookup or list of lookups
  """
  @spec by_lookup(lookup_or_lookups :: String.t() | [String.t()]) ::
          Role.t() | [Role.t()] | [] | nil
  def by_lookup(lookup_or_lookups) do
    GenServer.call(__MODULE__, {:lookup, lookup_or_lookups})
  end

  @doc """
  Reloads role cache with latest role configurations
  Non-blocking; does not return anything
  """
  @spec reload() :: no_return
  def reload() do
    GenServer.cast(__MODULE__, :reload)
  end

  ## === private functions ====

  # returns loaded role cache
  defp load() do
    all_roles = Role.all_repo()

    lookup_cache = map_by_keyname(all_roles, :lookup)

    {all_roles, lookup_cache}
  end

  defp map_by_keyname(roles, keyname) do
    roles
    |> Enum.reduce(%{}, fn role, lookup_cache ->
      lookup_cache |> Map.put(Map.get(role, keyname), role)
    end)
  end
end
