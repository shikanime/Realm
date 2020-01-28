defmodule Realm.Ord do
  @type t :: any()
  @type ordering :: :lesser | :equal | :greater

  @doc """
  Determine if two elements are `:equal`.
  ## Examples
      iex> equal?(1, 1.0)
      true
      iex> equal?(1, 2)
      false
  """
  @spec equal?(Ord.t(), Ord.t()) :: boolean()
  def equal?(a, b), do: Realm.Ord.Class.compare(a, b) == :equal

  @doc """
  Determine if an element is `:greater` than another.
  ## Examples
      iex> greater?(1, 1)
      false
      iex> greater?(1.1, 1)
      true
  """
  @spec greater?(Ord.t(), Ord.t()) :: boolean()
  def greater?(a, b), do: Realm.Ord.Class.compare(a, b) == :greater

  @doc """
  Determine if an element is `:lesser` than another.
  ## Examples
      iex> lesser?(1, 1)
      false
      iex> lesser?(1, 1.1)
      true
  """
  @spec lesser?(Ord.t(), Ord.t()) :: boolean()
  def lesser?(a, b), do: Realm.Ord.Class.compare(a, b) == :lesser
end

defprotocol Realm.Ord.Class do
  @doc """
  Get the ordering relationship between two elements.
  Possible results are `:lesser`, `:equal`, and `:greater`
  ## Examples
      iex> compare(1, 1)
      :equal
      iex> compare([1], [2])
      :lesser
      iex> compare([1, 2], [3])
      :lesser
      iex> compare([3, 2, 1], [1, 2, 3, 4, 5])
      :greater
  """
  @spec compare(Ord.t(), Ord.t()) :: Ord.ordering()
  def compare(ord_a, ord_b)
end
