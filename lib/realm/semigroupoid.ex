defprotocol Realm.Semigroupoid do
  @moduledoc """
  A semigroupoid describes some way of composing morphisms on between some
  collection of objects.
  ## Type Class
  An instance of `Realm.Semigroupoid` must define `Realm.Semigroupoid.compose/2`.
      Semigroupoid  [compose/2]
  """
  @doc """
  Take two morphisms and return their composition "the math way".
  That is, `(b -> c) -> (a -> b) -> (a -> c)`.
  ## Examples
      iex> times_ten_plus_one = compose(fn x -> x + 1 end, fn y -> y * 10 end)
      ...> times_ten_plus_one.(5)
      51
  """
  @spec compose(t(), t()) :: t()
  def compose(left, right)

  @doc """
  Express how to apply arguments to the _very end_ of a semigroupoid,
  or "run the morphism". This should not be used to inject values part way
  though a composition chain.
  It is provided here to remain idiomatic with Elixir, and to make
  prop testing _possible_.
  ## Examples
      iex> Realm.Semigroupoid.apply(&inspect/1, [42])
      "42"
  """
  @spec apply(t(), [any()]) :: t() | any()
  def apply(morphism, arguments)
end

defmodule Realm.Semigroupoid.Algebra do
  alias Realm.Semigroupoid

  @doc """
  Pipe some data through a morphism.
  Similar to `apply/2`, but with a single argument, not needing to wrap
  the argument in a list.
  ## Examples
      iex> import Realm.Semigroupoid.Algebra
      ...> pipe(42, &(&1 + 1))
      43
  """
  @spec pipe(any(), Semigroupoid.t()) :: any()
  def pipe(data, semigroupoid), do: Semigroupoid.apply(semigroupoid, [data])

  @doc """
  `compose/2`, but with the arguments flipped (same direction as `|>`).
  ## Examples
      iex> import Realm.Semigroupoid.Algebra
      ...> times_ten_plus_one = compose(fn y -> y * 10 end, fn x -> x + 1 end)
      ...> times_ten_plus_one.(5)
      51
  """
  @spec compose(Semigroupoid.t(), Semigroupoid.t()) :: Semigroupoid.t()
  def compose(left, right), do: Semigroupoid.compose(right, left)
end

defimpl Realm.Semigroupoid, for: Function do
  def apply(fun, args), do: Kernel.apply(fun, args)
  def compose(left, right), do: Quark.compose(left, right)
end
