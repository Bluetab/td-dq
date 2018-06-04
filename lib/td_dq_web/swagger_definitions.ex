defmodule TdDqWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def quality_control_definitions do
    %{
      QualityControl: swagger_schema do
        title "Quality Control"
        description "Quality Control entity"
        properties do
          id :integer, "unique identifier", required: true
          business_concept_id :string, "business concept id", required: true
          description :string, "description", required: true
          goal :integer, "goal percentage (1-100)"
          minimum :integer, "minimum goal (1-100)"
          name :string, "quality control name"
          population :string, "population target description"
          priority :string, "Priority (Medium,...)"
          weight :integer, "weight"
          status :string, "status (Default: defined)" #, default: "defined"
          version :integer, "version number"
          updated_by :integer, "updated by user id"
          principle :object, "quality control principle"
          type :string, "quality rule type"
          type_params :object, "quality rule type_params"
          quality_rules Schema.ref(:QualityRules)
        end
      end,
      QualityRule: swagger_schema do
        title "Quality Rule"
        description "Quality Rule entity"
        properties do
          id :integer, "Quality Rule unique identifier", required: true
          description :string, "Quality Rule description"
          name :string, "Quality Rule name", required: true
          type :string, "Quality Rule type", required: true
          system :string, "Quality Rule system", required: true
          system_params :object, "Quality Rule parameters", required: true
          tag :object, "Quality Rule tag"
          quality_control_id :integer, "Belongs to quality control", required: true
          quality_rule_type_id :integer, "Belongs to quality rule type", required: true
        end
      end,
      QualityRules: swagger_schema do
        title "Quality Rules"
        description "A collection of Quality Rules"
        type :array
        items Schema.ref(:QualityRule)
      end,
      QualityControlCreateProps: swagger_schema do
        properties do
          business_concept_id :string, "business concept id", required: true
          description :string, "description"
          goal :integer, "goal percentage (1-100)"
          minimum :integer, "minimum goal (1-100)"
          name :string, "quality control name", required: true
          population :string, "population target description"
          priority :string, "Priority (Medium,...)"
          weight :integer, "weight"
          status :string, "weight"
          version :integer, "weight"
          updated_by :integer, "weight"
          principle :object, "quality control principle"
          type :string, "weight"
          type_params :object, "weight"
        end
      end,
      QualityControlCreate: swagger_schema do
        properties do
          quality_control Schema.ref(:QualityControlCreateProps)
        end
      end,
      QualityControlUpdate: swagger_schema do
        properties do
          quality_control Schema.ref(:QualityControlCreateProps)
        end
      end,
      QualityControls: swagger_schema do
        title "Quality Controls"
        description "A collection of Quality Controls"
        type :array
        items Schema.ref(:QualityControl)
      end,
      QualityControlResponse: swagger_schema do
        properties do
          data Schema.ref(:QualityControl)
        end
      end,
      QualityControlsResponse: swagger_schema do
        properties do
          data Schema.ref(:QualityControls)
        end
      end
    }
  end

  def quality_rule_definitions do
    %{
      QualityRule: swagger_schema do
        title "Quality Rule"
        description "Quality Rule entity"
        properties do
          id :integer, "Quality Rule unique identifier", required: true
          description :string, "Quality Rule description"
          name :string, "Quality Rule name", required: true
          type :string, "Quality Rule type", required: true
          system :string, "Quality Rule system", required: true
          system_params :object, "Quality Rule parameters", required: true
          tag :object, "Quality Rule tag"
          quality_control_id :integer, "Belongs to quality control", required: true
          quality_rule_type_id :integer, "Belongs to quality rule type", required: true
        end
      end,
      QualityRuleCreateProps: swagger_schema do
        properties do
          description :string, "Quality Rule description"
          name :string, "Quality Rule name", required: true
          type :string, "Quality Rule type name", required: true
          system :string, "Quality Rule system", required: true
          system_params :object, "Quality Rule parameters", required: true
          tag :object, "Quality Rule tag"
          quality_control_id :integer, "belongs to quality control", required: true
        end
      end,
      QualityRuleCreate: swagger_schema do
        properties do
          quality_rule Schema.ref(:QualityRuleCreateProps)
        end
      end,
      QualityRuleUpdateProps: swagger_schema do
        properties do
          description :string, "Quality Rule description"
          name :string, "Quality Rule name", required: true
          type :string, "Quality Rule type name", required: true
          system :string, "Quality Rule system", required: true
          system_params :object, "Quality Rule parameters", required: true
          tag :object, "Quality Rule tag"
        end
      end,
      QualityRuleUpdate: swagger_schema do
        properties do
          quality_rule Schema.ref(:QualityRuleUpdateProps)
        end
      end,
      QualityRules: swagger_schema do
        title "Quality Rules"
        description "A collection of Quality Rules"
        type :array
        items Schema.ref(:QualityRule)
      end,
      QualityRuleResponse: swagger_schema do
        properties do
          data Schema.ref(:QualityRule)
        end
      end,
      QualityRulesResponse: swagger_schema do
        properties do
          data Schema.ref(:QualityRules)
        end
      end
    }
  end

  def quality_rule_type_definitions do
    %{
      QualityRuleType: swagger_schema do
        title "Quality Rule Type"
        description "Quality Rule Type entity"
        properties do
          id :integer, "Quality Rule Type unique identifier", required: true
          name :string, "Quality Rule Type name", required: true
          params :object, "Quality Rule Type parameters", required: true
        end
      end,
      QualityRuleTypeCreateProps: swagger_schema do
        properties do
          name :string, "Quality Rule Type name", required: true
          params :object, "Quality Rule Type parameters", required: true
        end
      end,
      QualityRuleTypeCreate: swagger_schema do
        properties do
          quality_rule_type Schema.ref(:QualityRuleTypeCreateProps)
        end
      end,
      QualityRuleTypeUpdateProps: swagger_schema do
        properties do
          name :string, "Quality Rule Type name", required: true
          params :object, "Quality Rule Type parameters", required: true
        end
      end,
      QualityRuleTypeUpdate: swagger_schema do
        properties do
          quality_rule_type Schema.ref(:QualityRuleTypeUpdateProps)
        end
      end,
      QualityRuleTypes: swagger_schema do
        title "Quality Rule Types"
        description "A collection of Quality Rule Types"
        type :array
        items Schema.ref(:QualityRuleType)
      end,
      QualityRuleTypeResponse: swagger_schema do
        properties do
          data Schema.ref(:QualityRuleType)
        end
      end,
      QualityRuleTypesResponse: swagger_schema do
        properties do
          data Schema.ref(:QualityRuleTypes)
        end
      end
    }
  end
end
