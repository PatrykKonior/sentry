defmodule Sentry.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Inicjalizuje tabelę ETS na endpointy (url -> pid monitora)
    :ok = Sentry.Store.init_table()

    children = [
      # startuję lokalny cache Nebulex
      {Sentry.Cache, []},
      # Registry do rejestrowania monitorów po URL
      {Registry, keys: :unique, name: Sentry.Registry},
      # DynamicSupervisor zarządzający monitorami
      Sentry.Supervisor.Supervisor
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Sentry.Application
    )

    # Wczytuję listę endpointów z config/config.exs (:sentry, :endpoints)
    endpoints =
      :sentry
      |> Application.get_env(:endpoints, [])
      |> Enum.map(&Sentry.Endpoint.new/1)

    Enum.each(endpoints, &Sentry.Supervisor.Supervisor.start_monitor/1)

    # opts = [strategy: :one_for_one, name: Sentry.Application]
    # Supervisor.start_link(children, opts)
    {:ok, self()}
  end
end
