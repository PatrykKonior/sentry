defmodule SentryTest do
  use ExUnit.Case
  doctest Sentry

  test "greets the world" do
    assert Sentry.hello() == :world
  end
end
