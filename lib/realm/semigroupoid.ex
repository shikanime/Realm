defmodule Realm.Semigroupoid do
  @type t :: any()

  @doc """
  Pipe some data through a morphism.
  Similar to `apply/2`, but with a single argument, not needing to wrap
  the argument in a list.
  ## Examples
      iex> Realm.Semigroupoid.pipe(42, &(&1 + 1))
      43
  """
  @spec pipe(any(), Realm.Semigroupoid.t()) :: any()
  def pipe(data, fun), do: apply(fun, [data])

  @doc """
  `compose/2`, but with the arguments flipped (same direction as `|>`).
  ## Examples
      iex> times_ten_plus_one = reverse_Realm.Semigroupoid.pipe(fn y -> y * 10 end, fn x -> x + 1 end)
      ...> times_ten_plus_one.(5)
      51
  """
  @spec reverse_pipe(t(), t()) :: t()
  def reverse_pipe(b, a), do: Realm.Semigroupoid.Class.compose(a, b)
end

defprotocol Realm.Semigroupoid.Class do
  @spec compose(Semigroupoid.t(), Semigroupoid.t()) :: Semigroupoid.t()
  def compose(morphism_a, morphism_b)

  @spec apply(Semigroupoid.t(), [any()]) :: Semigroupoid.t() | any()
  def apply(morphism, arguments)
end

defimpl Realm.Semigroupoid.Class, for: Function do
  def apply(fun, args), do: Kernel.apply(fun, args)
  def compose(f, g), do: Realm.compose(f, g)
end
