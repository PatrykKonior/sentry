defmodule Sentry.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Sentry.Registry},
      Sentry.Supervisor.Supervisor
      # Starts a worker by calling: Sentry.Worker.start_link(arg)
      # {Sentry.Worker, arg}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Sentry.Application
    )

    # na sztywno wpisane endpointy
    endpoints = [
      %{url: "google.com", protocol: :http, port: 443, frequency: 5_000},
      %{url: "example.com", protocol: :http, port: 80, frequency: 10_000},
      %{url: "smtp.gmail.com", protocol: :tcp, port: 587, frequency: 15_000}
    ]

    endpoints
    |> Enum.map(&Sentry.Endpoint.new/1)
    |> Enum.each(&Sentry.Supervisor.Supervisor.start_monitor/1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    # opts = [strategy: :one_for_one, name: Sentry.Application]
    # Supervisor.start_link(children, opts)
    {:ok, self()}
  end
end
