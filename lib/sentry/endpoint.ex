defmodule Sentry.Endpoint do
  # t :: to jest Type annotation czyli dokumentacja typów
  @type t :: %__MODULE__{
    url: String.t(),
    protocol: :http | :tcp,
    port: pos_integer() | nil, # port: number | null
    frequency: pos_integer() # tak samo number (DODATNI)
  }

  defstruct [:url, :protocol, :port, :frequency]
end
