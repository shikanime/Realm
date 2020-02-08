defprotocol Realm.Category do
  @moduledoc """
  A category is some collection of objects and relationships (morphisms) between them.
  This idea is captured by the notion of an identity function for objects,
  and the ability to compose relationships between objects. In most cases,
  these are very straightforward, and composition and identity are the standard
  functions from the `Quark` package or similar.
  ## Type Class
  An instance of `Realm.Category` must also implement `Realm.Semigroupoid`,
  and define `Realm.Category.identity/1`.
      Semigroupoid  [compose/2, apply/2]
          ↓
       Category     [identity/1]
  """

  @doc """
  Take some value and return it again.
  ## Examples
      iex> classic_id = Realm.Category.identity(fn -> nil end)
      ...> classic_id.(42)
      42
  """
  @spec identity(t()) :: t()
  def identity(category)
end

defimpl Realm.Category, for: Function do
  def identity(_), do: &Quark.id/1
end
