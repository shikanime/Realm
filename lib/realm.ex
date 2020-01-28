defmodule Realm do
  def a <> b do
    Realm.Semigroup.Class.append(a, b)
  end

  @doc """
  Composition operator "the math way". Alias for `compose/2`.
  ## Examples
      iex> times_ten_plus_one =
      ...>       fn x -> x + 1  end
      ...>   <|> fn y -> y * 10 end
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec Realm.Semigroupoid.t() <|> any() :: Realm.Semigroupoid.t()
  def g <|> f, do: Realm.Semigroupoid.Class.compose(g, f)

  @doc """
  Composition operator "the pipe way". Alias for `pipe_compose/2`.
  ## Examples
      iex> times_ten_plus_one =
      ...>       fn y -> y * 10 end
      ...>   <~> fn x -> x + 1  end
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec Realm.Semigroupoid.t() <~> any() :: Realm.Semigroupoid.t()
  def f <~> g, do: Realm.Semigroupoid.Class.compose(g, f)
end
