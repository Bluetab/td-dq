defmodule TdDqWeb.Router do
  use TdDqWeb, :router

  @endpoint_url "#{Application.get_env(:td_dq, TdDqWeb.Endpoint)[:url][:host]}:#{Application.get_env(:td_dq, TdDqWeb.Endpoint)[:url][:port]}"

  pipeline :api do
    plug TdDq.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TdDq.Auth.Pipeline.Secure
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_dq, swagger_file: "swagger.json"
  end

  scope "/api", TdDqWeb do
    pipe_through :api
    get  "/ping", PingController, :ping
    post "/echo", EchoController, :echo
  end

  scope "/api", TdDqWeb do
    pipe_through [:api, :api_secure]

    post "/quality_controls_results", QualityControlsResultsController, :upload
    get "/quality_controls_results", QualityControlsResultsController, :index
    get "/quality_controls/concept/:id", QualityControlController, :get_quality_controls_by_concept
    resources "/quality_controls", QualityControlController, except: [:new, :edit] do
      get "/quality_rules",  QualityRuleController, :get_quality_rules
    end
    resources "/quality_rules", QualityRuleController, except: [:new, :edit]
    resources "/quality_rule_types", QualityRuleTypeController, except: [:new, :edit]
  end

  def swagger_info do
    %{
      schemes: ["http"],
      info: %{
        version: "1.0",
        title: "QualityControl"
      },
      "host": @endpoint_url,
      "basePath": "/api",
      "securityDefinitions":
      %{
        bearer:
        %{
          "type": "apiKey",
          "name": "Authorization",
          "in": "header",
        }
      },
      "security": [
        %{
          bearer: []
        }
      ]
    }
  end

end
