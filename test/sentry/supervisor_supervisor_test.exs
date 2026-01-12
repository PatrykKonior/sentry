defmodule Sentry.Supervisor.SupervisorTest do
  @moduledoc """
    Test dla DynamicSupervisora
  """

  use ExUnit.Case, async: true

  alias Sentry.Endpoint
  alias Sentry.Store
  alias Sentry.Supervisor.Supervisor, as: SentrySupervisor

  test "starts monitor child for given endpoint and stores pid in ETS" do
    # inicjalizuję ETS lokalnie na potrzeby testu
    :ok = Store.init_table()

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

    # sprawdzam czy pid został zapisany w ETS pod danym url
    assert {:ok, ^pid} = Store.get("localhost")
  end
end
