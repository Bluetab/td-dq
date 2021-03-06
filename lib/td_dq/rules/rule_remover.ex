defmodule TdDq.Rules.RuleRemover do
  @moduledoc """
  This Module will be used to perform a soft removal of those rules which
  business concept has been deleted or deprecated
  """
  use GenServer

  alias TdCache.ConceptCache
  alias TdDq.Rules

  require Logger

  @rule_removal Application.compile_env(:td_dq, :rule_removal)
  @rule_removal_frequency Application.compile_env(:td_dq, :rule_removal_frequency)

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## GenServer Callbacks

  @impl true
  def init(state) do
    if @rule_removal, do: schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    case ConceptCache.active_ids() do
      {:ok, []} -> :ok
      {:ok, active_ids} -> soft_deletion(active_ids)
      _ -> :ok
    end

    schedule_work()
    {:noreply, state}
  end

  ## Private functions

  defp schedule_work do
    Process.send_after(self(), :work, @rule_removal_frequency)
  end

  defp soft_deletion([]), do: :ok

  defp soft_deletion(active_ids) do
    {:ok, %{rules: {rule_count, _}, deprecated: {impl_count, _}}} = Rules.soft_deletion(active_ids)

    if rule_count > 0, do: Logger.info("Soft deleted #{rule_count} rules")
    if impl_count > 0, do: Logger.info("Soft deleted #{impl_count} rule implementations")
    :ok
  end
end
