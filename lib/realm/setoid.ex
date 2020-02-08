defprotocol Realm.Setoid do
  @moduledoc ~S"""
  A setoid is a type with an equivalence relation.
  This is most useful when equivalence of some data is not the same as equality.
  Since some types have differing concepts of equality, this allows overriding
  the behaviour from `Kernel.==/2`. To get the Setoid `==` operator override,
  simply `use Realm.Setoid`.
  ## Type Class
  An instance of `Realm.Setoid` must define `Realm.Setoid.equivalent?/2`
      Setoid [equivalent?/2]
  """

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
  @spec equivalent?(t(), t()) :: boolean()
  def equivalent?(a, b)
end

defimpl Realm.Setoid, for: Integer do
  def equivalent?(int, num), do: Kernel.==(int, num)
end

defimpl Realm.Setoid, for: Float do
  def equivalent?(float, num), do: Kernel.==(float, num)
end

defimpl Realm.Setoid, for: BitString do
  def equivalent?(left, string_b), do: Kernel.==(left, string_b)
end

defimpl Realm.Setoid, for: Tuple do
  def equivalent?(left, right), do: Kernel.==(left, right)
end

defimpl Realm.Setoid, for: List do
  def equivalent?(left, right), do: Kernel.==(left, right)
end

defimpl Realm.Setoid, for: Map do
  def equivalent?(left, right), do: Kernel.==(left, right)
end

defimpl Realm.Setoid, for: MapSet do
  def equivalent?(left, right), do: MapSet.equal?(left, right)
end
