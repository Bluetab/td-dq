defmodule TdDqWeb.ImplementationFilterController do
  require Logger
  use TdDqWeb, :controller
  use PhoenixSwagger

  alias TdDq.Rules.Search
  alias TdDqWeb.SwaggerDefinitions

  plug :put_view, TdDqWeb.FilterView

  action_fallback(TdDqWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.filter_swagger_definitions()
  end

  swagger_path :search do
    description("List Implementation Filters")

    parameters do
      search(
        :body,
        Schema.ref(:FilterRequest),
        "Filter parameters"
      )
    end

    response(200, "OK", Schema.ref(:FilterResponse))
  end

  def search(conn, params) do
    user = conn.assigns[:current_resource]
    params = Map.put(params, :without, ["deleted_at"])
    filters = Search.get_filter_values(user, params, :implementations)
    render(conn, "show.json", filters: filters)
  end
end