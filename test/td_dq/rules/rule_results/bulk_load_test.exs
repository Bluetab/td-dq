defmodule TdDq.RuleResults.BulkLoadTest do
  use TdDq.DataCase

  import Ecto.Query, warn: false

  alias TdCache.ConceptCache
  alias TdCache.Redix
  alias TdCache.Redix.Stream
  alias TdCache.RuleCache
  alias TdDq.Cache.RuleLoader
  alias TdDq.MockRelationCache
  alias TdDq.Rules.RuleResults.BulkLoad
  alias TdDq.Search.MockIndexWorker

  @stream TdCache.Audit.stream()
  @concept_id 987_654_321

  setup_all do
    start_supervised(MockRelationCache)
    start_supervised(MockIndexWorker)
    start_supervised(RuleLoader)

    ConceptCache.put(%{id: @concept_id, domain_id: 42})

    on_exit(fn ->
      ConceptCache.delete(@concept_id)
      Redix.del!(@stream)
    end)
  end

  describe "bulk_load/1" do
    test "loads rule results and calculates status (number of errors)" do
      %{implementation_key: key, rule: %{result_type: result_type}} =
        insert(:implementation,
          rule: build(:rule, result_type: "errors_number", goal: 10, minimum: 20)
        )

      assert {:ok, res} =
               ["1", "15", "30"]
               |> Enum.map(
                 &string_params_for(:rule_result_record, implementation_key: key, errors: &1)
               )
               |> BulkLoad.bulk_load()

      assert %{results: results} = res
      assert [^result_type] = results |> Enum.map(& &1.result_type) |> Enum.uniq()

      assert Enum.group_by(results, & &1.errors, & &1.status) ==
               %{
                 1 => ["success"],
                 15 => ["warn"],
                 30 => ["fail"]
               }
    end

    test "loads rule results and calculates status (percentage)" do
      rule = build(:rule, result_type: "percentage", goal: 100, minimum: 80)

      %{implementation_key: key} = insert(:implementation, rule: rule)

      assert {:ok, res} =
               ["100", "90", "50"]
               |> Enum.map(
                 &string_params_for(:rule_result_record, implementation_key: key, result: &1)
               )
               |> BulkLoad.bulk_load()

      assert %{results: results} = res

      assert Enum.group_by(results, &Decimal.to_integer(&1.result), & &1.status) ==
               %{
                 50 => ["fail"],
                 90 => ["warn"],
                 100 => ["success"]
               }
    end

    test "publishes audit events with domain_ids" do
      rule =
        build(:rule,
          result_type: "percentage",
          goal: 100,
          minimum: 80,
          business_concept_id: "#{@concept_id}"
        )

      %{implementation_key: key} = insert(:implementation, rule: rule)
      params = %{"foo" => "bar"}

      assert {:ok, %{audit: [_, event_id, _]}} =
               ["100", "90", "50"]
               |> Enum.map(
                 &string_params_for(:rule_result_record, implementation_key: key, result: &1)
               )
               |> Enum.map(&Map.put(&1, "params", params))
               |> BulkLoad.bulk_load()

      assert {:ok, [event]} = Stream.range(:redix, @stream, event_id, event_id, transform: :range)
      assert %{event: "rule_result_created", payload: payload} = event

      assert %{"result" => "90.00", "status" => "warn", "params" => ^params, "domain_ids" => _} =
               Jason.decode!(payload)
    end

    test "refreshes rule cache" do
      %{id: rule_id, name: name} = rule = insert(:rule)
      %{implementation_key: key} = insert(:implementation, rule: rule)

      assert {:ok, _} =
               ["100", "90", "50"]
               |> Enum.map(
                 &string_params_for(:rule_result_record, implementation_key: key, result: &1)
               )
               |> BulkLoad.bulk_load()

      assert {:ok, %{name: ^name}} = RuleCache.get(rule_id)

      on_exit(fn -> RuleCache.delete(rule_id) end)
    end
  end
end
