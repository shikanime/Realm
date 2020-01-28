defmodule RealmTest do
  use ExUnit.Case
  doctest Realm

  test "greets the world" do
    assert Realm.hello() == :world
  end
end
