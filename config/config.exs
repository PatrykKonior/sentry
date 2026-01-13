import Config

config :sentry, Sentry.Cache,
  # dane bede dalej trzymal w ets ale zarzada tym nebulex
  backend: :ets,
  # gc - garbage collection, to jest czas w którym nebulex ma sprzątać stare albo wygasłe wpisy
  # robi to na razie co 12 godzin
  gc_interval: to_timeout(hour: 12),
  # maksymalna liczba wpisów w cache, jak liczba zostanie przekroczona to nebulex zacznie usuwać stare wpisy
  max_size: 1_000_000

config :sentry, :endpoints, [
  %{url: "google.com", protocol: :http, port: 443, frequency: 5_000},
  %{url: "example.com", protocol: :http, port: 80, frequency: 10_000},
  %{url: "smtp.gmail.com", protocol: :tcp, port: 587, frequency: 15_000}
]
