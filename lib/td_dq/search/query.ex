defmodule TdDq.Search.Query do
  @moduledoc """
    Helper module to manipulate elastic search queries.
  """
  alias TdDq.Search.Aggregations

  def create_filters(%{"filters" => filters}) do
    filters
    |> Map.to_list()
    |> Enum.map(&to_terms_query/1)
  end

  def create_filters(_), do: []

  def create_filter_clause(permissions, user_defined_filters) do
    should_clause =
      permissions
      |> Enum.filter(
        &Enum.any?(&1.permissions, fn p ->
          p == :view_quality_rule || p == :manage_confidential_business_concepts
        end)
      )
      |> Enum.map(&entry_to_filter_clause(&1, user_defined_filters))
      |> with_default_clause()

    %{bool: %{should: should_clause}}
  end

  defp entry_to_filter_clause(
         %{resource_id: resource_id, permissions: permissions},
         user_defined_filters
       ) do
    domain_clause = %{term: %{domain_ids: resource_id}}

    confidential_clause =
      case Enum.member?(permissions, :manage_confidential_business_concepts) do
        true -> %{terms: %{_confidential: [true, false]}}
        false -> %{terms: %{_confidential: [false]}}
      end

    %{
      bool: %{filter: user_defined_filters ++ [domain_clause, confidential_clause]}
    }
  end

  defp with_default_clause(filter_clauses) do
    filter_clauses ++
      [
        %{
          bool: %{
            filter: [
              %{terms: %{_confidential: [false]}},
              %{term: %{domain_ids: -1}}
              ]
            }
        }
      ]
  end

  defp to_terms_query({filter, values}) do
    Aggregations.aggregation_terms()
    |> Map.get(filter)
    |> get_filter(values)
  end

  defp get_filter(%{terms: %{field: field}}, values) do
    %{terms: %{field => values}}
  end

  defp get_filter(%{aggs: %{distinct_search: distinct_search}, nested: %{path: path}}, values) do
    %{nested: %{path: path, query: build_nested_query(distinct_search, values)}}
  end

  defp build_nested_query(%{terms: %{field: field}}, values) do
    %{terms: %{field => values}} |> bool_query([])
  end

  def create_query(%{"query" => query}, filter) do
    equery = add_query_wildcard(query)

    %{simple_query_string: %{query: equery}}
    |> bool_query(filter)
  end

  def create_query(_params, filter) do
    %{match_all: %{}}
    |> bool_query(filter)
  end

  defp bool_query(query, []), do: %{bool: %{must: query}}
  defp bool_query(query, filter), do: %{bool: %{must: query, filter: filter}}

  def add_query_wildcard(query) do
    case String.last(query) do
      nil -> query
      "\"" -> query
      ")" -> query
      " " -> query
      _ -> "#{query}*"
    end
  end
end
