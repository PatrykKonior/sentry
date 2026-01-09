defmodule Sentry.Supervisor.SupervisorTest do
  @moduledoc """
    Test dla DynamicSupervisora
  """

  use ExUnit.Case, async: true

  alias Sentry.Endpoint
  alias Sentry.Supervisor.Supervisor, as: SentrySupervisor

  test "starts monitor child for given endpoint" do
    # startujemy supervisora lokalnie na potrzeby testu,
    # bez używania globalnej nazwy z Application
    {:ok, _sup_pid} = DynamicSupervisor.start_link(SentrySupervisor, :ok)

    endpoint = %Endpoint{
      url: "localhost",
      protocol: :tcp,
      port: 65_000,
      frequency: 10
    }

    assert {:ok, pid} = SentrySupervisor.start_monitor(endpoint)
    assert Process.alive?(pid)
  end
end
