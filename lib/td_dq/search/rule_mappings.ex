defmodule TdDq.Search.RuleMappings do
  @moduledoc """
  Elastic Search mappings for Quality Rule
  """
  alias TdCache.TemplateCache

  def get_mappings do
    content_mappings = %{properties: get_dynamic_mappings()}

    mapping_type = %{
      id: %{type: "long"},
      business_concept_id: %{type: "text"},
      domain_ids: %{type: "long", null_value: -1},
      domain_parents: %{
        type: "nested",
        properties: %{
          id: %{type: "long"},
          name: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
      rule_type_id: %{type: "long"},
      version: %{type: "long"},
      name: %{type: "text", fields: %{raw: %{type: "keyword"}}},
      active: %{type: "boolean", fields: %{raw: %{type: "keyword", normalizer: "sortable"}}},
      description: %{type: "text", fields: %{raw: %{type: "keyword", normalizer: "sortable"}}},
      deleted_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
      updated_by: %{
        properties: %{
          id: %{type: "long"},
          user_name: %{type: "text", fields: %{raw: %{type: "keyword"}}},
          full_name: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
      current_business_concept_version: %{
        properties: %{
          id: %{type: "long"},
          name: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
      updated_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
      inserted_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
      goal: %{type: "long"},
      minimum: %{type: "long"},
      weight: %{type: "long"},
      population: %{type: "text", fields: %{raw: %{type: "keyword"}}},
      priority: %{type: "text", fields: %{raw: %{type: "keyword"}}},
      df_name: %{type: "text", fields: %{raw: %{type: "keyword"}}},
      rule_type: %{
        properties: %{
          id: %{type: "long"},
          name: %{fields: %{raw: %{type: "keyword"}}, type: "text"}
        }
      },
      type_params: %{
        properties: %{
          name: %{fields: %{raw: %{type: "keyword"}}, type: "text"}
        }
      },
      execution_result_info: %{
        properties: %{
          result_avg: %{type: "long"},
          last_execution_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
          result_text: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
      _confidential: %{type: "boolean"},
      df_content: content_mappings
    }

    settings = %{
      analysis: %{
        normalizer: %{
          sortable: %{type: "custom", char_filter: [], filter: ["lowercase", "asciifolding"]}
        }
      }
    }

    %{mappings: %{doc: %{properties: mapping_type}}, settings: settings}
  end

  defp get_dynamic_mappings do
    "dq"
    |> TemplateCache.list_by_scope!()
    |> Enum.flat_map(&get_mappings/1)
    |> Enum.into(%{})
  end

  defp get_mappings(%{content: content}) do
    content
    |> Enum.filter(&(Map.get(&1, "type") != "url"))
    |> Enum.map(&field_mapping/1)
  end

  defp field_mapping(%{"name" => name, "type" => "enriched_text"}) do
    {name, mapping_type("enriched_text")}
  end

  defp field_mapping(%{"name" => name, "values" => values}) do
    {name, mapping_type(values)}
  end

  defp field_mapping(%{"name" => name}) do
    {name, mapping_type("string")}
  end

  defp mapping_type(values) when is_map(values) do
    %{type: "text", fields: %{raw: %{type: "keyword"}}}
  end

  defp mapping_type(_default), do: %{type: "text"}
end
