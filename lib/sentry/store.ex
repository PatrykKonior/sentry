defmodule Sentry.Store do
  @moduledoc """
    Prosty wrapper na Nebulex do przechowywania mapowania endpoint URL -> pid monitora.
  """

  alias Sentry.Cache

  # inicjalizacja tabeli
  @spec init_table() :: :ok
  def init_table do
    # róznica jest taka, ze Nebulex sam inicjalizuje swoje struktury przy starcie Sentry.Cache
    # tutaj musze zostawic API jako no-op (no operation) czyli funkcja, która realnie nic nie robi tylko, np. zwraca :ok
    :ok
  end

  # to jest lista wszystkich wpisów
  @spec all() :: [{String.t(), pid()}]
  def all do
    # Cache.all() zwraca listę kluczy, np. ["one.example", "two.example", ...]
    Cache.all()
    |> Enum.map(fn url ->
      case Cache.get(url) do
        nil -> nil
        pid -> {url, pid}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # usunięcie wpisu po url -> pid
  @spec delete(String.t()) :: true
  def delete(url) do
    Cache.delete(url)
    true
  end

  # odczyt po url
  @spec get(String.t()) :: {:ok, pid()} | :error
  def get(url) do
    case Cache.get(url) do
      nil -> :error
      pid -> {:ok, pid}
    end
  end

  # zapis url -> pid
  @spec put(String.t(), pid()) :: true
  def put(url, pid) do
    Cache.put(url, pid)
    true
  end
end
