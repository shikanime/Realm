import Kernel, except: [<: 2, >: 2, <=: 2, >=: 2]

defprotocol Realm.Ord do
  @moduledoc ~S"""
  `Ord` describes how to order elements of a data type.
  This is a total order, so all elements are either `:equal`, `:greater`, or `:lesser`
  than each other.
  ## Type Class
  An instance of `Realm.Ord` must also implement `Realm.Setoid`,
  and define `Realm.Ord.compare/2`.
      Setoid  [equivalent?/2]
        ↓
       Ord    [compare/2]
  """

  @type ordering :: :lesser | :equal | :greater

  @doc """
  Get the ordering relationship between two elements.
  Possible results are `:lesser`, `:equal`, and `:greater`
  ## Examples
      iex> Realm.Ord.compare(1, 1)
      :equal
      iex> Realm.Ord.compare([1], [2])
      :lesser
      iex> Realm.Ord.compare([1, 2], [3])
      :lesser
      iex> Realm.Ord.compare([3, 2, 1], [1, 2, 3, 4, 5])
      :greater
  """
  @spec compare(t(), t()) :: ordering()
  def compare(left, right)
end

defmodule Realm.Ord.Algebra do
  alias Realm.Ord

  @doc """
  Determine if two elements are `:equal`.
  ## Examples
      iex> import Realm.Monoid.Algebra
      ...> equal?(1, 1.0)
      true
      iex> import Realm.Monoid.Algebra
      ...> equal?(1, 2)
      false
  """
  @spec equal?(Ord.t(), Ord.t()) :: boolean()
  def equal?(left, right), do: Ord.compare(left, right) == :equal
end
