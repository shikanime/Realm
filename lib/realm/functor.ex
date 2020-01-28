defprotocol Realm.Functor.Class do
  @spec map(Functor.t(), (any() -> any())) :: Functor.t()
  def map(wrapped, fun)
end

defimpl Realm.Functor.Class, for: Function do
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

defimpl Realm.Functor.Class, for: List do
  def map(list, fun), do: Enum.map(list, fun)
end

defimpl Realm.Functor.Class, for: Tuple do
  def map({}, _), do: {}

  def map(tuple, fun) do
    last_index = tuple_size(tuple) - 1
    mapped = tuple |> elem(last_index) |> fun.()
    put_elem(tuple, last_index, mapped)
  end
end

defimpl Realm.Functor.Class, for: Map do
  def map(map, fun) do
    map
    |> Map.to_list()
    |> Realm.Functor.map(fn {k, v} -> {k, fun.(v)} end)
    |> Enum.into(%{})
  end
end
