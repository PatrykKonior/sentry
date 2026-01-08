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

  @doc """
    Tworze endpoint z mapy
  """

  @spec new(map()) :: t()
  def new(%{url: url, protocol: protocol, port: port, frequency: frequency}) do
    %__MODULE__{
      url: url,
      protocol: protocol,
      port: port,
      frequency: frequency
    }
  end
end
