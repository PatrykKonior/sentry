defmodule Sentry.StoreTest do
  use ExUnit.Case, async: true

  alias Sentry.Store

  test "init_table creates ETS table idempotently" do
    # pierwsze wywołanie powinno utworzyć tabelę
    assert :ok = Store.init_table()

    # nie powinno być błedu ani tworzenia duplikatu
    assert :ok = Store.init_table()
  end

  test "put and get store and return pid by url" do
    Store.init_table()

    url = "example.com"
    pid = self()

    assert true == Store.put(url, pid)
    assert {:ok, ^pid} = Store.get(url)
  end

  test "get returns :error when url is not present" do
    Store.init_table()

    assert :error == Store.get("non-existent.example")
  end

  test "all returns all stored url-pid pairs" do
    Store.init_table()

    pid1 = spawn(fn -> :ok end)
    pid2 = spawn(fn -> :ok end)

    Store.put("one.example", pid1)
    Store.put("two.example", pid2)

    entries = Store.all()

    assert {"one.example", pid1} in entries
    assert {"two.example", pid2} in entries
  end
end
