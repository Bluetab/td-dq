defmodule TdDq.QualityControls.QualityControlsResults do
  @moduledoc false
  use Ecto.Schema

  schema "quality_controls_results" do
    field :business_concept_id, :string
    field :quality_control_name, :string
    field :system, :string
    field :group, :string
    field :structure_name, :string
    field :field_name, :string
    field :date, :utc_datetime
    field :result, :integer

    timestamps()
  end
end