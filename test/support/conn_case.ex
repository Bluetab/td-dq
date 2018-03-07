defmodule TdDqWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  alias Phoenix.ConnTest
  alias Ecto.Adapters.SQL.Sandbox
  import TdDqWeb.Authentication, only: :functions

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import TdDqWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint TdDqWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TdDq.Repo)
    unless tags[:async] do
      Sandbox.mode(TdDq.Repo, {:shared, self()})
    end
    if tags[:authenticated_user] do
        user_name = tags[:authenticated_user]
        create_user_auth_conn(user_name)
    else
        {:ok, conn: ConnTest.build_conn()}
    end
  end

end
