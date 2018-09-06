defmodule TdDqWeb.RuleImplementationController do
  require Logger
  use TdDqWeb, :controller
  use TdHypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdDq.Rules
  alias TdDq.Rules
  alias TdDq.Rules.RuleImplementation
  alias TdDq.Repo
  alias TdDqWeb.ErrorView
  alias TdDqWeb.SwaggerDefinitions

  action_fallback TdDqWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.rule_implementation_definitions()
  end

  swagger_path :index do
    description "List Quality Rules"
    response 200, "OK", Schema.ref(:RuleImplementationsResponse)
  end

  def index(conn, _params) do
    user = conn.assigns[:current_resource]
    with true <- can?(user, index(RuleImplementation)) do
      quality_rules = Rules.list_rule_implementations()
      render(conn, "index.json", rule_implementations: quality_rules)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      error ->
        Logger.error("While getting quality rules... #{inspect(error)}")
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :create do
    description "Creates a Quality Rule"
    produces "application/json"
    parameters do
      quality_rule :body, Schema.ref(:RuleImplementationCreate), "Quality Rule create attrs"
    end
    response 201, "Created", Schema.ref(:RuleImplementationResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"quality_rule" => quality_rule_params}) do
    user = conn.assigns[:current_resource]
    quality_control_id = Map.fetch!(quality_rule_params, "quality_control_id")
    quality_control = Rules.get_rule!(quality_control_id)

    # TODO: remove this!!!
    quality_rule_params = quality_rule_params
    |> Map.put("rule_id", quality_control.id)

    {quality_rule_params, quality_rule_type} =
      add_quality_rule_type_id(quality_rule_params)

    with true <- can?(user, create(%{
          "business_concept_id" => quality_control.business_concept_id,
          "resource_type" => "quality_rule"
          })),
         {:valid_quality_rule_type} <- verify_quality_rule_existence(quality_rule_type),
         {:ok_size_verification} <- verify_equals_sizes(quality_rule_params, quality_rule_type.params),
         {:ok_existence_verification} <- verify_types_and_existence(quality_rule_params, quality_rule_type.params),
         {:ok, %RuleImplementation{} = quality_rule} <- Rules.create_rule_implementation(quality_rule_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", rule_implementation_path(conn, :show, quality_rule))
      |> render("show.json", rule_implementation: quality_rule)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp verify_quality_rule_existence(quality_rule_type) do
    if quality_rule_type, do: {:valid_quality_rule_type},
    else: {:not_found_quality_rule_type}
  end

  defp verify_equals_sizes(%{"system_params" => quality_rule_params}, %{"system_params" => qrt_params}) do
    case length(Map.keys(quality_rule_params)) == length(qrt_params) do
      true -> {:ok_size_verification}
      false -> {:ko_size_verification}
    end
  end
  defp verify_equals_sizes(%{"system_params" => system_params}, _map_quality_rule_type) when system_params == %{}, do: {:ok_size_verification}
  defp verify_equals_sizes(_map_quality_rule, _map_quality_rule_type), do: {:no_system_params}

  defp verify_types_and_existence(map_quality_rule_params,
    map_quality_rule_type_params) do
      qr_tuple_list = Enum.map(map_quality_rule_params["system_params"], fn({k, v}) ->
        {k, get_type(v)}
      end)
      verify_key_type(qr_tuple_list, map_quality_rule_type_params["system_params"])
  end

  defp verify_key_type(_, _, {:error, error}), do: error
  defp verify_key_type([], _), do: {:ok_existence_verification}
  defp verify_key_type([{k, v}|tail], system_params) do
    system_param = Enum.find(system_params, fn(param) ->
      param["name"] == k
    end)
    cond do
      system_param == nil -> verify_key_type(nil, nil, {:error, "Element not found"})
      system_param["type"] != v -> verify_key_type(nil, nil, {:error, "Type does not match"})
      true ->   verify_key_type(tail, system_params)
    end
  end

  defp get_type(value) when is_integer(value), do: "integer"
  defp get_type(value) when is_float(value), do: "float"
  defp get_type(value) when is_list(value), do: "list"
  defp get_type(value) when is_boolean(value), do: "boolean"
  defp get_type(_), do: "string"

  swagger_path :show do
    description "Show Quality Rule"
    produces "application/json"
    parameters do
      id :path, :integer, "Quality Rule ID", required: true
    end
    response 200, "OK", Schema.ref(:RuleImplementationResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    quality_rule = Rules.get_rule_implementation!(id)
    user = conn.assigns[:current_resource]
    with true <- can?(user, show(quality_rule)) do
      render(conn, "show.json", rule_implementation: quality_rule)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :update do
    description "Updates Quality Rule"
    produces "application/json"
    parameters do
      quality_control :body, Schema.ref(:RuleImplementationUpdate), "Quality Rule update attrs"
      id :path, :integer, "Quality Rule ID", required: true
    end
    response 200, "OK", Schema.ref(:RuleImplementationResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "quality_rule" => quality_rule_params}) do
    quality_rule = Rules.get_rule_implementation!(id)
    quality_control = quality_rule.rule

    user = conn.assigns[:current_resource]
    with true <- can?(user, update(%{
        "business_concept_id" => quality_control.business_concept_id,
        "resource_type" => "quality_rule"
        })),
         {:ok, %RuleImplementation{} = quality_rule} <- Rules.update_rule_implementation(quality_rule, quality_rule_params) do
      render(conn, "show.json", rule_implementation: quality_rule)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :delete do
    description "Delete Quality Rule"
    produces "application/json"
    parameters do
      id :path, :integer, "Quality Rule ID", required: true
    end
    response 204, "No Content"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    quality_rule = Rules.get_rule_implementation!(id)
    user = conn.assigns[:current_resource]
    quality_control = quality_rule.rule

    with true <- can?(user, delete(%{
      "business_concept_id" => quality_control.business_concept_id,
      "resource_type" => "quality_rule"
      })),
         {:ok, %RuleImplementation{}} <- Rules.delete_rule_implementation(quality_rule) do
      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :get_rule_implementations do
    description "List Quality Rules"
    parameters do
      id :path, :integer, "Rule ID", required: true
    end
    response 200, "OK", Schema.ref(:RuleImplementationsResponse)
  end

  def get_rule_implementations(conn, %{"quality_control_id" => id}) do
    user = conn.assigns[:current_resource]
    quality_control_id = String.to_integer(id)

    with true <- can?(user, index(RuleImplementation)) do
      quality_rules = Rules.list_rule_implementations()

      # TODO: Search quality rules by quality control
      # TODO: Preload quality_control in search
      quality_rules = quality_rules
      |> Enum.map(&Repo.preload(&1, :rule))
      |> Enum.filter(&(&1.rule_id == quality_control_id))

      quality_controls_results = quality_rules
      |> Enum.reduce(%{}, fn(quality_rule, acc) ->
          Map.put(acc, quality_rule.id,
            get_concept_last_rule_result(quality_rule))
      end)

      render(conn, "index.json", rule_implementations: quality_rules,
                            quality_controls_results: quality_controls_results)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      error ->
        Logger.error("While getting quality rules... #{inspect(error)}")
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  # TODO: Search by implemnetation id
  defp get_concept_last_rule_result(quality_rule) do
    system_params = quality_rule.system_params
    table = Map.get(system_params, "table", nil)
    column = Map.get(system_params, "column", nil)
    case  table == nil or column == nil do
      true -> nil
      false -> nil
        Rules.get_concept_last_rule_result(
            quality_rule.rule.business_concept_id,
            quality_rule.rule.name,
            quality_rule.system,
            table,
            column)
    end
  end

  defp add_quality_rule_type_id(%{"type" => qrt_name} = quality_rule_params) do
    qrt = Rules.get_rule_type_by_name(qrt_name)
    case qrt do
      nil ->
        {quality_rule_params, nil}
      qrt ->
        {quality_rule_params
        |> Map.put("rule_type_id", qrt.id), qrt}
    end
  end
  defp add_quality_rule_type_id(%{"quality_rule_type_id" => quality_rule_type_id} = quality_rule_params),
    do: {quality_rule_params, Rules.get_rule_type!(quality_rule_type_id)}
  defp add_quality_rule_type_id(quality_rule_params), do: {quality_rule_params, nil}
end
