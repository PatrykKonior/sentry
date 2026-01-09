defmodule Sentry.Monitor.MonitorTest do
  @moduledoc """
    Test dla modułu Sentry.Monitor.Monitor
  """

  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Sentry.Endpoint
  alias Sentry.Monitor.Monitor

  # describe grupuje powiązane testy
  describe "HTTP monitor" do
    test "plogs UP when endpoint returns 200" do
      # Startuje lokalny serwer HTTP na losowym porcie
      # ten serwer będzie udawał endpoint HTTP zamiast prawdziwego na przykład google.com
      bypass = Bypass.open()

      # Bypass jako HTTP Server
      # funkcja ponizej ma za zadanie jak przyjdzie request HTTP na ten serwer wygenerować odpwowiedź
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      # buduje odpowiedni endpoint zgodnie z Sentry.Endpoint
      endpoint = %Endpoint{
        url: "localhost",
        protocol: :http,
        port: bypass.port,
        frequency: 10
      }

      # inicjalizacja monitora (bez start_link i procesów)
      {:ok, state} = Monitor.init(endpoint)

      # przechwycenie logów i symulacja handle_info(:check, state)
      # capture log odpala funkcję i zwraca string ze wszystkimi logami z Logger wygenerowanymi w środku
      log = capture_log(fn -> {:noreply, _new_state} = Monitor.handle_info(:check, state) end)

      # nowy operator nauczony -> =~ to operator „zawiera substring”
      # Jeśli check_status/1 poprawnie zalogowało Logger.info("UP: #{endpoint.url}"), to w log będzie występować "UP: localhost"
      #
      assert log =~ "UP: localhost"
    end

    # to samo co wyzej ale dla DOWN
    test "logs DOWN when endpoint returns 500" do
      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 500, "ERR")
      end)

      endpoint = %Endpoint{
        url: "localhost",
        protocol: :http,
        port: bypass.port,
        frequency: 10
      }

      {:ok, state} = Monitor.init(endpoint)

      log =
        capture_log(fn ->
          {:noreply, _new_state} = Monitor.handle_info(:check, state)
        end)

      assert log =~ "DOWN: localhost"
    end

    # testuje 404
    test "logs DOWN when endpoint returns 404" do
      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "Not found")
      end)

      endpoint = %Endpoint{
        url: "localhost",
        protocol: :http,
        port: bypass.port,
        frequency: 10
      }

      {:ok, state} = Monitor.init(endpoint)

      log =
        capture_log(fn ->
          {:noreply, _new_state} = Monitor.handle_info(:check, state)
        end)

      assert log =~ "DOWN: localhost"
    end
  end

  describe "TCP monitor" do
    test "placeholder" do
      assert true
    end
  end
end
