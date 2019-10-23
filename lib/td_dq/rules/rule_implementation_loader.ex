defmodule TdDq.Rules.RuleImplementation.Loader do
  @moduledoc """
  GenServer to run reindex task
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  import Ecto.Query

  alias TdDq.Rules
  alias TdDq.Repo
  alias TdCache.Redix
  alias TdCache.StructureCache

  require Logger

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def ping(timeout \\ 5000) do
    GenServer.call(__MODULE__, :ping, timeout)
  end

  ## EventStream.Consumer Callbacks

  @impl TdCache.EventStream.Consumer
  def consume(events) do
    GenServer.cast(__MODULE__, {:consume, events})
  end

  ## GenServer Callbacks

  @impl GenServer
  def init(state) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")

    unless Application.get_env(:td_dq, :env) == :test do
      Process.send_after(self(), :put_structure_ids, 0)
    end

    {:ok, state}
  end

  @impl true
  def handle_info(:put_structure_ids, state) do
    structure_ids = get_rule_implementations_structure_ids()
    Enum.map(structure_ids, &Rules.add_rule_implementation_structure_link/1)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:consume, events}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  ## Private functions

  defp get_rule_implementations_structure_ids() do
    rule_types =
      from(rt in "rule_types")
      |> select([rt], %{id: rt.id, params: rt.params})
      |> Repo.all()
      |> Enum.filter(&of_type_structure/1)

    rule_types_ids = Enum.map(rule_types, &Map.get(&1, :id))

    from(ri in "rule_implementations")
    |> join(:inner, [ri, r], r in "rules", on: r.id == ri.rule_id)
    |> join(:inner, [_, r, rt], rt in "rule_types", on: rt.id == r.rule_type_id)
    |> where([ri, _, _], is_nil(ri.deleted_at))
    |> where([_, r, _], is_nil(r.deleted_at))
    |> where([_, _, rt], rt.id in ^rule_types_ids)
    |> select([ri, _, rt], %{
      id: ri.id,
      system_params: ri.system_params,
      rule_type_id: rt.id,
      rule_type_params: rt.params
    })
    |> Repo.all()
    |> Enum.map(&get_structures_id/1)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp get_structures_id(%{
         id: id,
         system_params: system_params,
         rule_type_id: rule_type_id,
         rule_type_params: %{"system_params" => rule_type_params}
       }) do
    type_params_names =
      rule_type_params
      |> Enum.filter(fn param -> Map.get(param, "type") == "structure" end)
      |> Enum.map(fn param -> Map.get(param, "name") end)

    structure_ids =
      system_params
      |> Enum.filter(fn {key, value} -> key in type_params_names and Map.has_key?(value, "id") end)
      |> Enum.map(fn {key, value} ->
        Map.get(value, "id")
      end)

    structure_ids
  end

  defp get_structures_id(%{
         id: id,
         system_params: system_params,
         rule_type_id: rule_type_id,
         rule_type_params: _rule_type_params
       }) do
    []
  end

  defp of_type_structure(%{params: %{"system_params" => system_params}})
       when system_params == %{},
       do: false

  defp of_type_structure(%{params: nil}), do: false

  defp of_type_structure(%{params: %{"system_params" => system_params}}) do
    Enum.any?(system_params, &is_structure_type(&1))
  end

  defp of_type_structure(%{params: %{}}), do: false

  defp is_structure_type(system_params) do
    Map.get(system_params, "type") == "structure"
  end
end
