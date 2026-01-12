defmodule Sentry.ServiceTest do
  @moduledoc """
    Testy API do dynamicznego zarządzania monitorowanymi usługami
  """

  use ExUnit.Case, async: true

  alias Sentry.Service
  alias Sentry.Store

  describe "add/1" do
    test "starts monitor and stores pid in ETS" do
      # Inicjalizujemy ETS lokalnie dla testu
      :ok = Store.init_table()

      endpoint_params = %{
        url: "localhost-add-test",
        protocol: :tcp,
        port: 65_001,
        frequency: 10
      }

      assert {:ok, pid} = Service.add(endpoint_params)
      assert Process.alive?(pid)

      # sprawdzam czy pid został zapisany w ETS pod danym url
      assert {:ok, ^pid} = Store.get("localhost-add-test")
    end
  end
end
