defprotocol Realm.Monoid do
  @moduledoc ~S"""
  Monoid extends the semigroup with the concept of an "empty" or "zero" element.
  ## Type Class
  An instance of `Realm.Monoid` must also implement `Realm.Semigroup`,
  and define `Realm.Monoid.empty/1`.
      Semigroup  [append/2]
          ↓
       Monoid    [empty/1]
  """

  @doc ~S"""
  An "emptied out" or "starting position" of the passed data.
  ## Example
      iex> Realm.Monoid.empty(10)
      0
      iex> Realm.Monoid.empty [1, 2, 3, 4, 5]
      []
  """
  def empty(monoid)
end

defmodule Realm.Monoid.Algebra do
  alias Realm.{Monoid, Functor}

  def zero(monoid), do: Monoid.empty(monoid)

  @doc """
  Check if a value is the empty element of that type.
  ## Examples
      iex> import Realm.Monoid.Algebra
      ...> empty?([])
      true
      iex> import Realm.Monoid.Algebra
      ...> empty?([1])
      false
  """
  @spec empty?(Monoid.t()) :: boolean
  def empty?(monoid), do: Monoid.empty(monoid) == monoid

  @doc ~S"""
  `map` with its arguments flipped.
  ## Examples
      iex> import Realm.Monoid.Algebra
      ...> across(fn x -> x + 1 end, [1, 2, 3])
      [2, 3, 4]
      iex> import Realm.Monoid.Algebra
      ...> fn
      ...>   int when is_integer(int) -> int * 100
      ...>   value -> inspect(value)
      ...> end
      ...> |> .across(%{a: 2, b: [1, 2, 3]})
      %{a: 200, b: "[1, 2, 3]"}
  """
  @spec across((any() -> any()), Functor.t()) :: Functor.t()
  def across(fun, functor), do: Functor.map(functor, fun)
end

defimpl Realm.Monoid, for: Function do
  def empty(monoid) when is_function(monoid), do: &Quark.id/1
end

defimpl Realm.Monoid, for: Integer do
  def empty(_), do: 0
end

defimpl Realm.Monoid, for: Float do
  def empty(_), do: 0.0
end

defimpl Realm.Monoid, for: BitString do
  def empty(_), do: ""
end

defimpl Realm.Monoid, for: List do
  def empty(_), do: []
end

defimpl Realm.Monoid, for: Map do
  def empty(_), do: %{}
end

defimpl Realm.Monoid, for: Tuple do
  def empty(monoid), do: Realm.Functor.map(monoid, &Realm.Monoid.empty/1)
end

defimpl Realm.Monoid, for: MapSet do
  def empty(_), do: MapSet.new()
end
