defmodule Sentry.Service do
  @moduledoc """
    API do dynamicznego zarządzania monitorowanymi usługami
  """

  alias Sentry.Endpoint
  alias Sentry.Monitor.Monitor
  alias Sentry.Supervisor.Supervisor, as: SentrySupervisor

  @doc """
  Dodaje nowy endpoint do monitorowania w runtime.

  Przyjmuje mapę z kluczami:
    * :url - adres hosta (np. "google.com" lub "localhost")
    * :protocol - :http lub :tcp
    * :port - numer portu
    * :frequency - częstotliwość sprawdzania w milisekundach

  Zwraca `{:ok, pid}` albo `{:error, reason}` z `Sentry.Supervisor.Supervisor.start_monitor/1`.
  """

  @spec add(map()) :: {:ok, pid()} | {:error, term()}
  def add(endpoint_params) do
    endpoint = Endpoint.new(endpoint_params)
    SentrySupervisor.start_monitor(endpoint)
  end

  @doc """
  Zatrzymuje monitorowanie endpointu o podanym URL (pauza w runtime).

  Zwracam:
    * :ok - gdy monitor istnieje i został spauzowany,
    * {:error, :not_found} - gdy brak monitora dla danego URL.
  """
  @spec pause(String.t()) :: :ok | {:error, :not_found}
  def pause(url) do
    case Sentry.Store.get(url) do
      {:ok, pid} ->
        :ok = Monitor.pause(pid)
        :ok

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Usuwam endpoint z monitorowania w runtime.

  Szukam pid po URL w ETS i jeśli znajde:
    * zatrzymuje dziecko w DynamicSupervisor,
    * usuwam wpis z ETS.

  Zwracam:
    * :ok - gdy monitor został poprawnie usunięty,
    * {:error, :not_found} - gdy nie ma takiego endpointu w ETS,
    * {:error, reason} - gdy terminate_child zwrócił błąd.
  """
  @spec remove(String.t()) :: :ok | {:error, :not_found | term()}
  def remove(url) do
    # szukam PID mając URL w ETS
    with {:ok, pid} <- Sentry.Store.get(url),
         # teraz usuwam proces monitora z globalnego supervisora
         :ok <- DynamicSupervisor.terminate_child(SentrySupervisor, pid) do
      # tutaj czyszczę wpis w ETS
      Sentry.Store.delete(url)
      :ok
    else
      :error -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Wznawia monitorowanie endpointu o podanym URL (resume w runtime).

  Zwraca:
    * :ok - gdy monitor istnieje i został wznowiony,
    * {:error, :not_found} - gdy brak monitora dla danego URL.
  """
  @spec resume(String.t()) :: :ok | {:error, :not_found}
  def resume(url) do
    case Sentry.Store.get(url) do
      {:ok, pid} ->
        :ok = Monitor.resume(pid)
        :ok

      :error ->
        {:error, :not_found}
    end
  end
end
