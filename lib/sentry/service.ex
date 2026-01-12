defmodule Sentry.Service do
  @moduledoc """
    API do dynamicznego zarządzania monitorowanymi usługami
  """

  alias Sentry.Endpoint
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
end
