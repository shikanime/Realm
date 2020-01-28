defmodule Realm.Setoid do
  @type t :: any()

  @doc """
  The opposite of `equivalent?/2`.
  ## Examples
      iex> nonequivalent?(1, 2)
      true
  """
  @spec nonequivalent?(Realm.Setoid.t(), Realm.Setoid.t()) :: boolean()
  def nonequivalent?(a, b), do: not Realm.Setoid.Class.equivalent?(a, b)
end

defprotocol Realm.Setoid.Class do
  @doc ~S"""
  Compare two setoids and determine if they are equivalent.
  Aliased as `==`.
  ## Examples
      iex> equivalent?(1, 2)
      false
      iex> import Kernel, except: [==: 2, !=: 2]
      ...> %{a: 1} == %{a: 1, b: 2}
      false
      equivalent?(%Maybe.Just{just: 42}, %Maybe.Nothing{})
      #=> false
  ### Equivalence not equality
      baby_harry = %Wizard{name: "Harry Potter", age: 10}
      old_harry  = %Wizard{name: "Harry Potter", age: 17}
      def chosen_one?(some_wizard), do: equivalent?(baby_harry, some_wizard)
      chosen_one?(old_harry)
      #=> true
  """
  @spec equivalent?(Realm.Setoid.t(), Realm.Setoid.t()) :: boolean()
  def equivalent?(a, b)
end

defimpl Realm.Setoid.Class, for: Integer do
  def equivalent?(int, num), do: Kernel.==(int, num)
end

defimpl Realm.Setoid.Class, for: Float do
  def equivalent?(float, num), do: Kernel.==(float, num)
end

defimpl Realm.Setoid.Class, for: BitString do
  def equivalent?(string_a, string_b), do: Kernel.==(string_a, string_b)
end

defimpl Realm.Setoid.Class, for: Tuple do
  def equivalent?(tuple_a, tuple_b), do: Kernel.==(tuple_a, tuple_b)
end

defimpl Realm.Setoid.Class, for: List do
  def equivalent?(list_a, list_b), do: Kernel.==(list_a, list_b)
end

defimpl Realm.Setoid.Class, for: Map do
  def equivalent?(map_a, map_b), do: Kernel.==(map_a, map_b)
end

defimpl Realm.Setoid.Class, for: MapSet do
  def equivalent?(a, b), do: MapSet.equal?(a, b)
end
