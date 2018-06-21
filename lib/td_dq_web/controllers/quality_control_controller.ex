defmodule TdDqWeb.QualityControlController do
  use TdDqWeb, :controller
  use PhoenixSwagger

  alias TdDq.Audit
  alias TdDq.QualityControls
  alias TdDq.QualityControls.QualityControl
  alias TdDqWeb.ErrorView
  alias TdDqWeb.SwaggerDefinitions

  action_fallback(TdDqWeb.FallbackController)

  @events %{create_quality_control: "create_quality_control"}

  def swagger_definitions do
    SwaggerDefinitions.quality_control_definitions()
  end

  swagger_path :index do
    description("List Quality Controls")
    response(200, "OK", Schema.ref(:QualityControlsResponse))
  end

  def index(conn, _params) do
    quality_controls = QualityControls.list_quality_controls()
    render(conn, "index.json", quality_controls: quality_controls)
  end

  swagger_path :get_quality_controls_by_concept do
    description("List Quality Controls of a Business Concept")

    parameters do
      id(:path, :string, "Business Concept ID", required: true)
    end

    response(200, "OK", Schema.ref(:QualityControlsResponse))
  end

  def get_quality_controls_by_concept(conn, %{"id" => id}) do
    quality_controls = QualityControls.list_concept_quality_controls(id)
    render(conn, "index.json", quality_controls: quality_controls)
  end

  swagger_path :create do
    description("Creates a Quality Control")
    produces("application/json")

    parameters do
      quality_control(:body, Schema.ref(:QualityControlCreate), "Quality Control create attrs")
    end

    response(201, "Created", Schema.ref(:QualityControlResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"quality_control" => quality_control_params}) do
    quality_control_params =
      if conn.assigns.current_user do
        Map.put_new(quality_control_params, "updated_by", conn.assigns.current_user.id)
      else
        quality_control_params
      end

    with {:ok, %QualityControl{} = quality_control} <-
           QualityControls.create_quality_control(quality_control_params) do
      audit = %{
        "audit" => %{
          "resource_id" => quality_control.id,
          "resource_type" => "quality_control",
          "payload" => quality_control_params
        }
      }

      Audit.create_event(conn, audit, @events.create_quality_control)

      conn
      |> put_status(:created)
      |> put_resp_header("location", quality_control_path(conn, :show, quality_control))
      |> render("show.json", quality_control: quality_control)
    else
      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :show do
    description("Show Quality Control")
    produces("application/json")

    parameters do
      id(:path, :integer, "Quality Control ID", required: true)
    end

    response(200, "OK", Schema.ref(:QualityControlResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    quality_control = QualityControls.get_quality_control!(id)
    render(conn, "show.json", quality_control: quality_control)
  end

  swagger_path :update do
    description("Updates Quality Control")
    produces("application/json")

    parameters do
      quality_control(:body, Schema.ref(:QualityControlUpdate), "Quality Control update attrs")
      id(:path, :integer, "Quality Control ID", required: true)
    end

    response(200, "OK", Schema.ref(:QualityControlResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "quality_control" => quality_control_params}) do
    quality_control = QualityControls.get_quality_control!(id)

    quality_control_params =
      if conn.assigns.current_user do
        Map.put_new(quality_control_params, "updated_by", conn.assigns.current_user.id)
      else
        quality_control_params
      end

    with {:ok, %QualityControl{} = quality_control} <-
           QualityControls.update_quality_control(quality_control, quality_control_params) do
      render(conn, "show.json", quality_control: quality_control)
    end
  end

  swagger_path :delete do
    description("Delete Quality Control")
    produces("application/json")

    parameters do
      id(:path, :integer, "Quality Control ID", required: true)
    end

    response(200, "OK")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    quality_control = QualityControls.get_quality_control!(id)

    with {:ok, %QualityControl{}} <- QualityControls.delete_quality_control(quality_control) do
      send_resp(conn, :no_content, "")
    end
  end
end
