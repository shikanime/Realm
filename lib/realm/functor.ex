defprotocol Realm.Functor do
  @moduledoc ~S"""
  Functors are datatypes that allow the application of functions to their interior values.
  Always returns data in the same structure (same size, tree layout, and so on).
  Please note that bitstrings are not functors, as they fail the
  functor composition constraint. They change the structure of the underlying data,
  and thus composed lifting does not equal lifing a composed function. If you
  need to map over a bitstring, convert it to and from a charlist.
  ## Type Class
  An instance of `Realm.Functor` must define `Realm.Functor.map/2`.
      Functor  [map/2]
  """

  @doc ~S"""
  `map` a function into one layer of a data wrapper.
  There is an autocurrying variant: `lift/2`.
  ## Examples
      iex> Realm.Functor.map([1, 2, 3], fn x -> x + 1 end)
      [2, 3, 4]
      iex> %{a: 1, b: 2} ~> fn x -> x * 10 end
      %{a: 10, b: 20}
      iex> Realm.Functor.map(%{a: 2, b: [1, 2, 3]}, fn
      ...>   int when is_integer(int) -> int * 100
      ...>   value -> inspect(value)
      ...> end)
      %{a: 200, b: "[1, 2, 3]"}
  """
  @spec map(Functor.t(), (any() -> any())) :: Functor.t()
  def map(wrapped, fun)
end

defmodule Realm.Functor.Algebra do
  use Quark
  alias Realm.Functor

  @doc ~S"""
  Replace all inner elements with a constant value
  ## Examples
      iex> import Realm.Functor.Algebra
      ...> replace([1, 2, 3], "hi")
      ["hi", "hi", "hi"]
  """
  @spec replace(Functor.t(), any()) :: Functor.t()
  def replace(functor, value), do: Functor.map(functor, curry(&constant(value, &1)))
end

defimpl Realm.Functor, for: Function do
  use Quark

  @doc """
  Compose functions
  ## Example
      iex> ex = Realm.Functor.lift(fn x -> x * 10 end, fn x -> x + 2 end)
      ...> ex.(2)
      22
  """
  def map(f, g), do: Quark.compose(g, f)
end

defimpl Realm.Functor, for: List do
  def map(list, fun), do: Enum.map(list, fun)
end

defimpl Realm.Functor, for: Tuple do
  def map(tuple, fun) do
    case tuple do
      {} ->
        {}

      {first} ->
        {fun.(first)}

      {first, second} ->
        {first, fun.(second)}

      {first, second, third} ->
        {first, second, fun.(third)}

      {first, second, third, fourth} ->
        {first, second, third, fun.(fourth)}

      {first, second, third, fourth, fifth} ->
        {first, second, third, fourth, fun.(fifth)}

      big_tuple ->
        last_index = tuple_size(big_tuple) - 1

        mapped =
          big_tuple
          |> elem(last_index)
          |> fun.()

        put_elem(big_tuple, last_index, mapped)
    end
  end
end

defimpl Realm.Functor, for: Map do
  def map(hashmap, fun) do
    hashmap
    |> Map.to_list()
    |> Realm.Functor.map(fn {key, value} -> {key, fun.(value)} end)
    |> Enum.into(%{})
  end
end
