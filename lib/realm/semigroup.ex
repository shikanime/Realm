defprotocol Realm.Semigroup do
  @moduledoc ~S"""
  A semigroup is a structure describing data that can be appendenated with others of its type.
  That is to say that appending another list returns a list, appending one map
  to another returns a map, and appending two integers returns an integer, and so on.
  These can be chained together an arbitrary number of times. For example:
      1 <> 2 <> 3 <> 5 <> 7 == 18
      [1, 2, 3] <> [4, 5, 6] <> [7, 8, 9] == [1, 2, 3, 4, 5, 6, 7, 8, 9]
      "foo" <> " " <> "bar" == "foo bar"
  This generalizes the idea of a monoid, as it does not require an `empty` version.
  ## Type Class
  An instance of `Realm.Semigroup` must define `Realm.Semigroup.append/2`.
      Semigroup  [append/2]
  """

  @doc ~S"""
  `append`enate two data of the same type. These can be chained together an arbitrary number of times. For example:
      iex> 1 |> append(2) |> append(3)
      6
      iex> [1, 2, 3]
      ...> |> append([4, 5, 6])
      ...> |> append([7, 8, 9])
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      iex> "foo" |> append(" ") |> append("bar")
      "foo bar"
  """
  def append(a, b)
end

defmodule Realm.Semigroup.Algebra do
  alias Realm.Semigroup

  @doc ~S"""
  Flatten a list of homogeneous semigroups to a single container.
  ## Example
      iex> concat [
      ...>   [1, 2, 3],
      ...>   [4, 5, 6]
      ...> ]
      [1, 2, 3, 4, 5, 6]
  """
  @spec concat(Semigroup.t()) :: [Semigroup.t()]
  def concat(semigroups) do
    Enum.reduce(semigroups, [], &Semigroup.append(&2, &1))
  end

  @doc ~S"""
  Repeat the contents of a semigroup a certain number of times.
  ## Examples
      iex> [1, 2, 3] |> repeat(3)
      [1, 2, 3, 1, 2, 3, 1, 2, 3]
  """
  @spec repeat(Semigroup.t(), non_neg_integer()) :: Semigroup.t()
  # credo:disable-for-lines:6 Credo.Check.Refactor.PipeChainStart
  def repeat(subject, n) do
    fn -> subject end
    |> Stream.repeatedly()
    |> Stream.take(n)
    |> Enum.reduce(&Semigroup.append(&2, &1))
  end
end

defimpl Realm.Semigroup, for: Function do
  def append(f, g) when is_function(g), do: Quark.compose(g, f)
end

defimpl Realm.Semigroup, for: Integer do
  def append(a, b), do: a + b
end

defimpl Realm.Semigroup, for: Float do
  def append(a, b), do: a + b
end

defimpl Realm.Semigroup, for: BitString do
  def append(a, b), do: Kernel.<>(a, b)
end

defimpl Realm.Semigroup, for: List do
  def append(a, b), do: a ++ b
end

defimpl Realm.Semigroup, for: Map do
  def append(a, b), do: Map.merge(a, b)
end

defimpl Realm.Semigroup, for: MapSet do
  def append(a, b), do: MapSet.union(a, b)
end

defimpl Realm.Semigroup, for: Tuple do
  def append(left, right) do
    left
    |> Tuple.to_list()
    |> Enum.zip(Tuple.to_list(right))
    |> Enum.map(fn {x, y} -> Realm.Semigroup.append(x, y) end)
    |> List.to_tuple()
  end
end
