defmodule Sentry.Monitor.Monitor do
  @moduledoc """
    GenServer, który ma za zadanie monitorować jeden endpoint (HTTP/TCP)
    Sporadycznie sprawdza status oraz loguje wynik
  """
  use GenServer

  require Logger

  @doc """
    Rozpoczęcie monitora dla zadanego endpointa
  """

  # spec to dokumentacja typów funkcji
  # start_link przyjmuje Sentry.Endpoint, zwraca GenServer.on_start()
  @spec start_link(Sentry.Endpoint.t()) :: GenServer.on_start()
  def start_link(endpoint) do
    GenServer.start_link(__MODULE__, endpoint, name: via_tuple(endpoint))
  end

  # Private functions

  # wywołuje tylko gdy protocol = http
  defp check_status(%{protocol: :http} = endpoint) do
    case Req.get(endpoint.url, timeout: 5000) do
      {:ok, %{status: status}} when status in 200..599 ->
        Logger.info("UP: #{endpoint.url}")

      _ ->
        Logger.warning("DOWN: #{endpoint.url}")
    end
  end

  # wywołuje tylko gdy protocol = tcp
  defp check_status(%{protocol: :tcp, port: port} = endpoint) do
    # :gen_tcp.connect() -> to jest otworzenie połączenia tcp
    # to_charlist("google.com") = [103,111,111,103,108,101,46,99,111,109] (bajty)
    case :gen_tcp.connect(to_charlist(endpoint.url), port || 80, [], 5000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        Logger.info("UP: #{endpoint.url}:#{port}")

      _ ->
        Logger.warning("DOWN: #{endpoint.url}:#{port}")
    end
  end

  # sprawdzamy frequency endpointu
  defp schedule_check(%{frequency: freq}) do
    # przy odpowiednim freq sekund otrzymuję wiadomość :check
    Process.send_after(self(), :check, freq * 1000)
  end

  # przez jaki kanał mamy znaleźć proces
  defp via_tuple(endpoint) do
    # Registry to centralny rejestr procesów Elixir, Sentry.Registry -> nazwa rejestru
    {:via, Registry, {Sentry.Registry, endpoint.url}}
  end

  @impl true
  def init(endpoint) do
    Logger.info("Starting monitor for #{endpoint.url} (#{endpoint.frequency}s)")
    schedule_check(endpoint)
    {:ok, endpoint}
  end

  @impl true
  def handle_info(:check, endpoint) do
    check_status(endpoint)
    schedule_check(endpoint)
    {:noreply, endpoint}
  end
end
