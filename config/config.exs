import Config

config :sentry, :endpoints, [
  %{url: "google.com", protocol: :http, port: 443, frequency: 5_000},
  %{url: "example.com", protocol: :http, port: 80, frequency: 10_000},
  %{url: "smtp.gmail.com", protocol: :tcp, port: 587, frequency: 15_000}
]
