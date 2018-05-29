defmodule TdDq.QualityRules.QualityRuleType do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdDq.QualityRules.QualityRuleType
  alias TdDq.QualityRules.QualityRule

  schema "quality_rule_type" do
    field :name, :string
    field :params, :map

    timestamps()
  end

  @doc false
  def changeset(%QualityRuleType{} = quality_rule_type, attrs) do
    quality_rule_type
    |> cast(attrs, [:name, :params])
    |> validate_required([:name, :params])
  end
end