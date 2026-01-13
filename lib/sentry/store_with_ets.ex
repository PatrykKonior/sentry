defmodule Sentry.StoreWithEts do
  @moduledoc """
    Prosty wrapper na ETS do przechowywania mapowania endpoint URL -> pid monitora.
  """

  @doc """
    1. ETS (Erlang Term Storage) to wbudowana, ultra szybka pamięć key–value w VM,
    dostępna z dowolnego procesu, trzymana w pamięci RAM.
    2. URL -> PID monitor i szybkie znajdywanie procesu po adresie
  """

  @table :sentry_endpoints

  # tutaj tworze tabelę ETS
  @spec init_table() :: :ok
  def init_table do
    # rozpoczynam od dowiedzenia się czy tabela o nazwie :sentry_endpoints w ogóle istnieje
    # jak nie istnieje to niech zwraca undefined
    case :ets.info(@table) do
      # jak nie istnieje to chce zwrócić nową tabele
      # :set - 1 klucz 1 wartość (jak map) :public - kazdy proces moze get i put do tej tabeli
      # :named_table - tabela ma nazwe wiec nie trzymam jej id w zmiennej tylko atom
      # read_concurrency: true – optymalizacja do szybkiego, równoległego czytania
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
        :ok

      # jak istnieje to po prostu nic nie robie - funkcja idempotentna
      _info ->
        :ok
    end
  end

  # to jest lista wszystkich wpisów
  @spec all() :: [{String.t(), pid()}]
  def all do
    # zwracam cała zawartość tabeli jako listę {url, pid}
    :ets.tab2list(@table)
  end

  # usunięcie wpisu po url -> pid
  @spec delete(String.t()) :: true
  def delete(url) do
    :ets.delete(@table, url)
  end

  # odczyt po url
  @spec get(String.t()) :: {:ok, pid()} | :error
  def get(url) do
    # tutaj zwracam listę dopasowanych wpisów albo pustą listę
    case :ets.lookup(@table, url) do
      # pierwszy pattern matching - ^url -> klucz musi by dokładnie tym samym url, który przekazałem w arg fn
      # wyciągam pid i zwracam {:ok, pid}
      [{^url, pid}] -> {:ok, pid}
      # jak puste to error bo nic nie znalazłem
      [] -> :error
    end
  end

  # zapis url -> pid
  @spec put(String.t(), pid()) :: true
  def put(url, pid) do
    :ets.insert(@table, {url, pid})
  end
end
