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

  @doc """
    Zwracam aktualny status monitora (:running lub :paused).
  """
  @spec status(pid() | GenServer.name()) :: :running | :paused
  def status(server) do
    GenServer.call(server, :status)
  end

  @doc """
    Zatrzymuje sprawdzanie endpointu (ustawia status na :paused).
  """
  @spec pause(pid() | GenServer.name()) :: :ok
  def pause(server) do
    GenServer.cast(server, :pause)
  end

  @doc """
    Wznawia sprawdzanie endpointu (ustawia status na :running).
  """
  @spec resume(pid() | GenServer.name()) :: :ok
  def resume(server) do
    GenServer.cast(server, :resume)
  end

  # Private functions

  # wywołuje tylko gdy protocol = http
  defp check_status(%{protocol: :http} = endpoint) do
    # musi być takze obsługa https bo mam errory
    # dodana takze obsługa https po porcie oraz portu w URL jezeli zostanie podany - wyszło przy testowaniu
    # poprawne statusy dla up i down - wyszlo po testowaniu
    scheme = if endpoint.port == 443, do: "https://", else: "http://"

    full_url =
      case endpoint.port do
        nil -> "#{scheme}#{endpoint.url}"
        port -> "#{scheme}#{endpoint.url}:#{port}"
      end

    case Req.get(full_url) do
      {:ok, %{status: status}} when status in 200..299 ->
        Logger.info("UP: #{endpoint.url}")

      {:ok, %{status: status}} when status in 300..599 ->
        Logger.warning("DOWN: #{endpoint.url}")

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
    Process.send_after(self(), :check, freq)
  end

  # przez jaki kanał mamy znaleźć proces
  defp via_tuple(endpoint) do
    # Registry to centralny rejestr procesów Elixir, Sentry.Registry -> nazwa rejestru
    {:via, Registry, {Sentry.Registry, endpoint.url}}
  end

  @impl true
  def init(endpoint) do
    Logger.info("Starting monitor for #{endpoint.url} (#{div(endpoint.frequency, 1000)}s)")
    schedule_check(endpoint)

    # state, który przetrzymuje mi endpoint + jego aktualny stan
    state = %{endpoint: endpoint, status: :running}

    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, %{status: status} = state) do
    {:reply, status, state}
  end

  # zmiana statusu na pauze
  @impl true
  def handle_cast(:pause, %{status: _old} = state) do
    new_state = %{state | status: :paused}
    {:noreply, new_state}
  end

  # zmiana statusu znow na running
  @impl true
  def handle_cast(:resume, %{status: _old} = state) do
    new_state = %{state | status: :running}
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:check, %{endpoint: endpoint, status: status} = state) do
    # tutaj check -> jezeli monitor jest uruchomiony to robie check
    if status == :running do
      check_status(endpoint)
    end

    schedule_check(endpoint)
    {:noreply, state}
  end
end
