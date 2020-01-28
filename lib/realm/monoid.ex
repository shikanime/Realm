defmodule Realm.Monoid do
  @type t :: any()

  @doc """
  Check if a value is the empty element of that type.
  ## Examples
      iex> empty?([])
      true
      iex> empty?([1])
      false
  """
  @spec empty?(Realm.Monoid.t()) :: boolean
  def empty?(monoid), do: Realm.Monoid.Class.empty(monoid) == monoid
end

defprotocol Realm.Monoid.Class do
  def empty(sample)
end

defimpl Realm.Monoid.Class, for: Function do
  def empty(fun) when is_function(fun), do: &Quark.id/1
end

defimpl Realm.Monoid.Class, for: Integer do
  def empty(_), do: 0
end

defimpl Realm.Monoid.Class, for: Float do
  def empty(_), do: 0.0
end

defimpl Realm.Monoid.Class, for: BitString do
  def empty(_), do: ""
end

defimpl Realm.Monoid.Class, for: List do
  def empty(_), do: []
end

defimpl Realm.Monoid.Class, for: Map do
  def empty(_), do: %{}
end

defimpl Realm.Monoid.Class, for: Tuple do
  def empty(tuple), do: Realm.Functor.map(tuple, &Realm.Monoid.empty/1)
end

defimpl Realm.Monoid.Class, for: MapSet do
  def empty(_), do: MapSet.new()
end
