defmodule Sentry.Endpoint do
  # t :: to jest Type annotation czyli dokumentacja typów
  @type t :: %__MODULE__{
          url: String.t(),
          protocol: :http | :tcp,
          # port: number | null
          port: pos_integer() | nil,
          # tak samo number (DODATNI)
          frequency: pos_integer()
        }

  defstruct [:url, :protocol, :port, :frequency]
end
