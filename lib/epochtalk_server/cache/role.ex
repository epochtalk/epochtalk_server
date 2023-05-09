defmodule EpochtalkServer.Cache.Role do
  use GenServer
  use Ecto.Schema
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Role

  @moduledoc """
  `Role` cache genserver, stores roles in memory for quick lookup
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_call({:lookup, lookups}, _from, role_cache) when is_list(lookups) do
    {:reply,
     Map.take(role_cache, lookups)
     |> Enum.map(fn {_k, v} -> v end)
     |> Enum.sort(&(&1.id < &2.id)), role_cache}
  end

  @impl true
  def handle_call({:lookup, lookup}, _from, role_cache) do
    {:reply, Map.get(role_cache, lookup), role_cache}
  end

  @impl true
  def handle_cast(:reload, _role_cache), do: {:noreply, load()}

  ## === cache api functions ====

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Returns a `Role` or list of `Role`s for specified lookup or list of lookups
  """
  @spec by_lookup(lookup_or_lookups :: String.t() | [String.t()]) :: Role.t() | [Role.t()] | [] | nil
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

  # returns loaded role cache
  defp load() do
    Role
    |> Repo.all()
    |> Enum.reduce(%{}, fn role, role_cache -> role_cache |> Map.put(role.lookup, role) end)
  end
end
