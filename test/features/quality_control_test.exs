defmodule TrueBG.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "quality_control.feature"
  use TdDqWeb.ConnCase
  import TdDqWeb.Router.Helpers
  import TdDqWeb.ResponseCode
  import TdDqWeb.Authentication, only: :functions
  alias Poison, as: JSON
  @endpoint TdDqWeb.Endpoint

  @test_to_api_create_alias %{"Field" => "field", "Type" => "type", "Business Concept ID" => "business_concept_id",
    "Name" => "name", "Description" => "description", "Weight" => "weight",
    "Priority" => "priority", "Population" => "population", "Goal" => "goal", "Minimum" => "minimum"
  }

  @test_to_api_get_alias %{"Status" => "status", "Last User" => "updated_by", "Version" => "version"}

  @quality_control_integer_fields ["weight", "goal", "minimum"]
  # Scenario

  defgiven ~r/^user "(?<user_name>[^"]+)" is logged in the application$/, %{user_name: user_name}, state do
    {:ok, token, _full_claims} = sign_in(user_name)
    {:ok,  Map.merge(state, %{status_code: 402, token: token, user_name: user_name})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to create a Quality Control of type "(?<type>[^"]+)" with following data:$/,
    %{user_name: user_name, type: _type, table: table}, state do

    assert user_name == state[:user_name]
    attrs = table
    |> field_value_to_api_attrs(@test_to_api_create_alias)
    |> cast_to_int_attrs(@quality_control_integer_fields)
    {:ok, status_code, json_resp} = quality_control_create(state[:token], attrs)
    quality_control_json = json_resp["data"]
    Enum.each(attrs, fn({k, _v}) ->
              assert attrs[k] == quality_control_json[k]
              end
            )
    if table[:"Last Modification"] do
      assert quality_control_json["inserted_at"] != nil
    end
   {:ok,  Map.merge(state, %{status_code: status_code})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  defand ~r/^"(?<user_name>[^"]+)" is able to view quality control with Business Concept ID "(?<business_concept_id>[^"]+)" and name "(?<name>[^"]+)" with following data:$/,
    %{user_name: user_name, business_concept_id: business_concept_id,
      name: name, table: table}, state do

    assert user_name == state[:user_name]
    quality_control_data = get_quality_control(state[:token], %{business_concept_id: business_concept_id, name: name})

    attrs = table
    |> field_value_to_api_attrs(Map.merge(@test_to_api_create_alias, @test_to_api_get_alias))
    |> cast_to_int_attrs(@quality_control_integer_fields ++ ["version"])

    attrs =
      if attrs["Last Modification"] do
        assert quality_control_data["inserted_at"] != nil
        Map.drop(attrs, ["Last Modification"])
      else
        attrs
    end
    Enum.each(attrs, fn({k, _v}) ->
      assert attrs[k] == quality_control_data[k]
    end
    )
  end

  def cast_to_int_attrs(m, keys) do
    m
    |> Map.split(keys)
    |> fn({l1, l2}) ->
        l1 |>
        Enum.map(fn({k, v}) ->
          {k, String.to_integer(v)} end
        )
        |> Enum.into(l2)
       end.()
  end

  defp get_quality_control(token, search_params) do
    {:ok, _status_code, json_resp} = quality_control_list(token)
    Enum.find(json_resp["data"], fn(quality_control) ->
      Enum.all?(search_params, fn({k, v}) ->
        string_key = Atom.to_string(k)
        quality_control[string_key] == v
      end
      )
    end
    )
  end

  defp field_value_to_api_attrs(table, key_alias_map) do
    table
    |> Enum.reduce(%{}, fn(x, acc) ->
        Map.put(acc, Map.get(key_alias_map,  x."Field", x."Field"), x."Value")
        end
       )
  end

  defp quality_control_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(quality_control_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp quality_control_create(token, quality_control_params) do
    headers = get_header(token)
    body = %{quality_control: quality_control_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(quality_control_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
