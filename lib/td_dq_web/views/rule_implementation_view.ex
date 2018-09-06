defmodule TdDqWeb.RuleImplementationView do
  use TdDqWeb, :view
  alias TdDqWeb.RuleImplementationView

  def render("index.json", %{rule_implementations: rule_implementations} = assigns) do

    %{data: render_many(rule_implementations,
      RuleImplementationView, "rule_implementation.json",
      Map.drop(assigns, [:rule_implementations]))
    }
  end

  def render("show.json", %{rule_implementation: rule_implementation} = assigns) do
    %{data: render_one(rule_implementation,
      RuleImplementationView, "rule_implementation.json",
      Map.drop(assigns, [:rule_implementation]))
    }
  end

  def render("rule_implementation.json", %{rule_implementation: rule_implementation} = assigns) do
    %{
      id: rule_implementation.id,
      quality_control_id: rule_implementation.rule_id,
      quality_rule_type_id: rule_implementation.rule_type_id,
      name: rule_implementation.name,
      description: rule_implementation.description,
      system: rule_implementation.system,
      system_params: rule_implementation.system_params,
      type: rule_implementation.type,
      tag: rule_implementation.tag
    }
    |> add_rule_type(rule_implementation)
    |> add_rule(rule_implementation)
    |> add_rule_result(assigns)
  end

  defp add_rule_type(quality_rule, qr) do
    case Ecto.assoc_loaded?(qr.rule_type) do
      true ->
        quality_rule_type = %{
          id: qr.rule_type.id,
          name: qr.rule_type.name,
          params: qr.rule_type.params
        }

        Map.put(quality_rule, :quality_rule_type, quality_rule_type)

      _ ->
        quality_rule
    end
  end

  defp add_rule(quality_rule, qr) do
    case Ecto.assoc_loaded?(qr.rule) do
      true ->
        quality_control = %{id: qr.rule.id, name: qr.rule.name}
        Map.put(quality_rule, :rule, quality_control)

      _ ->
        quality_rule
    end
  end

  defp add_rule_result(quality_rule, assigns) do
    case Map.get(assigns, :quality_controls_results) do
      nil -> quality_rule
      quality_controls_results ->
        case Map.get(quality_controls_results, quality_rule.id) do
          nil ->
            quality_rule
            |> Map.put(:results, [])
          quality_controls_result ->
            quality_rule
            |> Map.put(:results,
                  [%{result: quality_controls_result.result,
                     date: quality_controls_result.date}])
        end
    end
  end

end
