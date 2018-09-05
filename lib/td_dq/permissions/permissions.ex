defmodule TdDq.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias TdDq.Accounts.User

  @permission_resolver Application.get_env(:td_dq, :permission_resolver)

  @doc """
  Check if user has a permission in a domain.

  ## Examples

      iex> authorized?(%User{}, "create", 12)
      false

  """
  def authorized?(%User{jti: jti}, permission, business_concept_id) do
    @permission_resolver.has_permission?(jti, permission, "business_concept", business_concept_id)
  end

end