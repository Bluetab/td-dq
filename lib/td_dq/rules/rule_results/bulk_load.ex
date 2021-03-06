defmodule TdDq.Rules.RuleResults.BulkLoad do
  @moduledoc """
  The Rule Results context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias TdDq.Cache.RuleLoader
  alias TdDq.Repo
  alias TdDq.Rules.Audit
  alias TdDq.Rules.Implementations.Implementation
  alias TdDq.Rules.RuleResult

  require Logger

  def bulk_load(records) do
    Logger.info("Loading rule results...")

    Timer.time(
      fn -> do_bulk_load(records) end,
      fn millis, _ -> Logger.info("Rule results loaded in #{millis}ms") end
    )
  end

  defp do_bulk_load(records) do
    Multi.new()
    |> Multi.run(:ids, fn _, _ -> bulk_insert(records) end)
    |> Multi.run(:results, &select_results/2)
    |> Multi.run(:audit, Audit, :rule_results_created, [0])
    |> Repo.transaction()
    |> bulk_refresh()
  end

  defp bulk_refresh(res) do
    with {:ok, %{results: results}} <- res,
         rule_ids <- rule_ids_from_results(results) do
      RuleLoader.refresh(rule_ids)
      res
    end
  end

  defp rule_ids_from_results(results) do
    results
    |> Enum.map(&Map.get(&1, :rule_id))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp bulk_insert(records) do
    result_type_map = result_type_map(records)

    records
    |> Enum.with_index(2)
    |> Enum.map(fn {params, row_number} -> Map.put(params, "row_number", row_number) end)
    |> Enum.map(&changeset(&1, result_type_map))
    |> Enum.reduce_while([], &reduce_changesets/2)
    |> case do
      ids when is_list(ids) -> {:ok, ids}
      error -> error
    end
  end

  defp result_type_map(records) do
    keys =
      records
      |> Enum.map(&Map.get(&1, "implementation_key"))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    Implementation
    |> where([ri], ri.implementation_key in ^keys)
    |> join(:inner, [ri], rule in assoc(ri, :rule))
    |> select([ri, r], {ri.implementation_key, r.result_type})
    |> Repo.all()
    |> Map.new()
  end

  defp changeset(%{} = params, %{} = result_type_map) do
    with %{"implementation_key" => key} <- params,
         type when is_binary(type) <- Map.get(result_type_map, key) do
      params
      |> Map.put("result_type", type)
      |> RuleResult.changeset()
    else
      _ -> RuleResult.changeset(params)
    end
  end

  defp reduce_changesets(%{} = changeset, acc) do
    case Repo.insert(changeset) do
      {:ok, %{id: id}} -> {:cont, [id | acc]}
      error -> {:halt, error}
    end
  end

  defp select_results(_repo, %{ids: ids}) do
    results =
      RuleResult
      |> join(:inner, [r], i in Implementation, on: r.implementation_key == i.implementation_key)
      |> join(:inner, [res, i], rule in assoc(i, :rule))
      |> select([res], %{})
      |> select_merge(
        [res, _, _],
        map(res, ^~w(id implementation_key date result errors records params inserted_at)a)
      )
      |> select_merge([_, i, _], %{implementation_id: i.id, rule_id: i.rule_id})
      |> select_merge(
        [_, _, rule],
        map(rule, ^~w(business_concept_id goal name minimum result_type)a)
      )
      |> where([res], res.id in ^ids)
      |> order_by([res], res.id)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :status, status(&1)))

    {:ok, results}
  end

  defp status(%{result_type: "errors_number", errors: errors, minimum: threshold, goal: target}) do
    cond do
      Decimal.compare(errors, threshold) == :gt -> "fail"
      Decimal.compare(errors, target) == :gt -> "warn"
      true -> "success"
    end
  end

  defp status(%{result_type: "percentage", result: result, minimum: threshold, goal: target}) do
    cond do
      Decimal.compare(result, threshold) == :lt -> "fail"
      Decimal.compare(result, target) == :lt -> "warn"
      true -> "success"
    end
  end
end
