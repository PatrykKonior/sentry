defmodule Sentry.Supervisor.Supervisor do
  @moduledoc """
    Implementacja DynamicSupervisor który zarządza Sentry.Monitor procesem

    Startuje i zatrzymuje monitoring dynamicznie dla danego endpointa.
  """

  use DynamicSupervisor

  @doc """
    Rozpoczynam Supervisora.
  """
  @spec start_link(term()) :: {:ok, pid()} | {:error, term()}
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
    Start monitora dla zadanego endpointa
  """
  @spec start_monitor(Sentry.Endpoint.t()) :: {:ok, pid()} | {:error, term()}
  def start_monitor(endpoint) do
    # uruchamiam sentry.monitor z danym endpointem
    spec = {Sentry.Monitor.Monitor, endpoint}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    # strategia :one_for_one -> jak dziecko sie wywali to tylko restart tylko tego dziecka
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
