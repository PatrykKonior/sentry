defmodule Sentry.ServiceTest do
  @moduledoc """
    Testy API do dynamicznego zarządzania monitorowanymi usługami
  """

  use ExUnit.Case, async: true

  alias Sentry.Monitor.Monitor
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

  describe "remove/1" do
    test "stops monitor and removes it from ETS" do
      :ok = Store.init_table()

      endpoint_params = %{
        url: "localhost-remove-test",
        protocol: :tcp,
        port: 65_002,
        frequency: 10
      }

      # najpierw dodajemy monitor
      assert {:ok, pid} = Service.add(endpoint_params)
      assert Process.alive?(pid)
      assert {:ok, ^pid} = Store.get("localhost-remove-test")

      # teraz usuwamy
      assert :ok = Service.remove("localhost-remove-test")

      # wpis w ETS powinien zniknąć
      assert :error = Store.get("localhost-remove-test")

      # proces monitora nie powinien już żyć
      refute Process.alive?(pid)
    end

    test "returns :not_found when url is not present" do
      :ok = Store.init_table()

      assert {:error, :not_found} = Service.remove("non-existent-service")
    end
  end

  describe "pause/1 and resume/1" do
    test "pauses and resumes existing monitor by url" do
      :ok = Store.init_table()

      endpoint_params = %{
        url: "localhost-pause-service-test",
        protocol: :http,
        port: 65_200,
        frequency: 10
      }

      # startuje monitor przez Service
      assert {:ok, pid} = Service.add(endpoint_params)
      assert :running == Monitor.status(pid)

      # pauza po URL
      assert :ok = Service.pause("localhost-pause-service-test")
      # małe okno na cast
      Process.sleep(10)
      assert :paused == Monitor.status(pid)

      # robie resume aby wrocil do zywych
      assert :ok = Service.resume("localhost-pause-service-test")
      Process.sleep(10)
      assert :running == Monitor.status(pid)
    end

    test "returns :not_found for pause/resume when url is missing" do
      :ok = Store.init_table()

      assert {:error, :not_found} = Service.pause("non-existent-service")
      assert {:error, :not_found} = Service.resume("non-existent-service")
    end
  end
end
