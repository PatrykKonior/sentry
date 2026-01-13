defmodule Sentry.Cache do
  @moduledoc """
  Lokalny cache oparty o Nebulex.

  Służy jako backend dla Sentry.Store zamiast ręcznie zarządzanego ETS.
  """

  # tworze moduł cache dla aplikacji sentry z lokalnym adapterem
  use Nebulex.Cache,
    otp_app: :sentry,
    # cache działa w jednym nodzie, dane sa trzymanie lokalnie i nie ma komunikacji pomiedzy nodami
    adapter: Nebulex.Adapters.Local
end
