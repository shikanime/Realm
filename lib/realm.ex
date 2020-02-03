import Kernel, except: [==: 2, !=: 2, <>: 2, apply: 2]

defmodule Realm do
  use Quark
  alias Realm.{Semigroupoid, Semigroup, Arrow, Apply, Ord, Setoid, Functor}

  @doc """
  Composition operator "the math way". Alias for `compose/2`.
  ## Examples
      iex> times_ten_plus_one =
      ...>       fn x -> x + 1  end
      ...>   <|> fn y -> y * 10 end
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec Semigroupoid.t() <|> any() :: Semigroupoid.t()
  defdelegate compose(g, f), to: Semigroupoid, as: :compose
  defdelegate g <|> f, to: __MODULE__, as: :compose

  @doc """
  Composition operator "the pipe way". Alias for `compose/2`.
  ## Examples
      iex> times_ten_plus_one =
      ...>       fn y -> y * 10 end
      ...>   <~> fn x -> x + 1  end
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec Semigroupoid.t() <~> any() :: Semigroupoid.t()
  def flow_compose(f, g), do: Semigroupoid.compose(g, f)
  defdelegate f <~> g, to: __MODULE__, as: :flow_compose

  @doc ~S"""
  There is an operator alias `a <> b`. Since this conflicts with `Kernel.<>/2`,
  `use Realm,Semigroup` will automatically exclude the Kernel operator.
  This is highly recommended, since `<>` behaves the same on bitstrings, but is
  now available on more datatypes.
  ## Examples
      iex> use Realm.Semigroup
      ...> 1 <> 2 <> 3 <> 5 <> 7
      18
      iex> use Realm.Semigroup
      ...> [1, 2, 3] <> [4, 5, 6] <> [7, 8, 9]
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      iex> use Realm.Semigroup
      ...> "foo" <> " " <> "bar"
      "foo bar"
  """
  defdelegate append(left, right), to: Semigroup
  defdelegate left <> right, to: __MODULE__, as: :append

  @doc """
  Take two arguments (as a 2-tuple), and run one function on the left side (first element),
  and run a different function on the right side (second element).
        ┌------> f.(a) = x -------┐
        |                         v
      {a, b}                    {x, y}
        |                         ^
        └------> g.(b) = y -------┘
  ## Examples
      iex> arr = fn x -> x - 10 end ^^^ fn y -> y <> "!" end
      ...> arr.({42, "Hi"})
      {32, "Hi!"}
      iex> {42, "Hi"} |> (fn x -> x - 10 end ^^^ fn y -> y <> "!" end).()
      {32, "Hi!"}
  """
  @spec product(Arrow.t(), Arrow.t()) :: Arrow.t()
  def product(f, g), do: Arrow.Algebra.first(f) <~> Arrow.Algebra.second(g)
  defdelegate left ^^^ right, to: __MODULE__, as: :product

  @doc """
  Duplicate incoming data into both halves of a 2-tuple, and run one function
  on the left copy, and a different function on the right copy.
               ┌------> f.(a) = x ------┐
               |                        v
      a ---> split = {a, a}           {x, y}
               |                        ^
               └------> g.(a) = y ------┘
  ## Examples
      iex> fanned = fn x -> x - 10 end &&& fn y -> inspect(y) <> "!" end
      ...> fanned.(42)
      {32, "42!"}
      iex> fanned =
      ...>   fn x -> x - 10 end
      ...>   &&& fn y -> inspect(y) <> "!" end
      ...>   &&& fn z -> inspect(z) <> "?" end
      ...>   &&& fn d -> inspect(d) <> inspect(d) end
      ...>   &&& fn e -> e / 2 end
      ...>
      ...> fanned.(42)
      {{{{32, "42!"}, "42?"}, "4242"}, 21.0}
  """
  @spec fanout(Arrow.t(), Arrow.t()) :: Arrow.t()
  def fanout(f, g), do: f |> Arrow.arrowize(&Arrow.Algebra.split/1) <~> (f ^^^ g)
  defdelegate left &&& right, to: __MODULE__, as: :fanout

  @doc """
  Determine if an element is `:greater` than another.
  ## Examples
      iex> greater?(1, 1)
      false
      iex> greater?(1.1, 1)
      true
  """
  @spec greater?(Ord.t(), Ord.t()) :: boolean()
  def greater?(left, right), do: Ord.compare(left, right) == :greater
  defdelegate left > right, to: __MODULE__, as: :greater?

  @doc """
  Determine if an element is `:lesser` than another.
  ## Examples
      iex> lesser?(1, 1)
      false
      iex> lesser?(1, 1.1)
      true
  """
  @spec lesser?(Ord.t(), Ord.t()) :: boolean()
  def lesser?(left, right), do: Ord.compare(left, right) == :lesser
  defdelegate left < right, to: __MODULE__, as: :lesser?

  @doc """
  Determine if an element is `:lesser` or `:equal` to another.
  ## Examples
      iex> use Realm.Ord
      ...> 1 <= 2
      true
      ...> [] <= [1, 2, 3]
      false
      ...> [1] <= [1, 2, 3]
      true
      ...> [4] <= [1, 2, 3]
      false
  """
  @spec Ord.t() <= Ord.t() :: boolean()
  def at_most?(left, right), do: Ord.compare(left, right) != :greater
  defdelegate left <= right, to: __MODULE__, as: :at_most?

  @doc """
  Determine if an element is `:greater` or `:equal` to another.
  ## Examples
      iex> use Realm.Ord
      ...> 2 >= 1
      true
      ...> [1, 2, 3] >= []
      true
      ...> [1, 2, 3] >= [1]
      true
      ...> [1, 2, 3] >= [4]
      false
  """
  @spec Ord.t() >= Ord.t() :: boolean()
  def at_least?(left, right), do: Ord.compare(left, right) != :lesser
  defdelegate left >= right, to: __MODULE__, as: :at_least?

  @doc """
  Determine if an element is equal to another.
  ## Examples
      iex> use Realm.Ord
      ...> 2 == 1
      false
      ...> 1 == 1
      true
  """
  def equal?(left, right), do: Setoid.equivalent?(left, right)
  defdelegate left == right, to: __MODULE__, as: :equal?

  @doc """
  The opposite of `equivalent?/2`.
  ## Examples
      iex> nonequivalent?(1, 2)
      true
  """
  @spec nonequivalent?(Setoid.t(), Setoid.t()) :: boolean()
  def nonequivalent?(left, right), do: not Setoid.equivalent?(left, right)
  defdelegate left != right, to: __MODULE__, as: :nonequivalent?

  @doc ~S"""
  `map/2` but with the function automatically curried
  ## Examples
      iex> [1, 2, 3]
      ...> ~> fn x -> x + 55 end
      ...> ~> fn y -> y * 10 end
      [560, 570, 580]
      iex> [1, 2, 3]
      ...> ~> fn(x, y) -> x + y end
      ...> |> List.first()
      ...> |> apply([9])
      10
  """
  @spec lift(Functor.t(), fun()) :: Functor.t()
  def lift(functor, fun), do: Functor.map(functor, curry(fun))
  defdelegate functor ~> fun, to: __MODULE__, as: :lift

  @doc """
  `lift/2` but with arguments flipped.
      iex> (fn x -> x + 5 end) <~ [1,2,3]
      [6, 7, 8]
  Note that the mnemonic is flipped from `|>`, and combinging directions can
  be confusing. It's generally recommended to use `~>`, or to keep `<~` on
  the same line both of it's arguments:
      iex> fn(x, y) -> x + y end <~ [1, 2, 3]
      ...> |> List.first()
      ...> |> apply([9])
      10
  ...or in an expression that's only pointing left:
      iex> fn y -> y * 10 end
      ...> <~ fn x -> x + 55 end
      ...> <~ [1, 2, 3]
      [560, 570, 580]
  """
  @spec over(fun(), Functor.t()) :: Functor.t()
  def over(fun, functor), do: lift(functor, fun)
  defdelegate fun <~ functor, to: __MODULE__, as: :over

  @doc """
  Same as `ap/2`, but with all functions curried.
  ## Examples
      iex> [fn x -> x + 1 end, fn y -> y * 10 end] <<~ [1, 2, 3]
      [2, 3, 4, 10, 20, 30]
      iex> import Realm.Functor
      ...>
      ...> [100, 200]
      ...> ~> fn(x, y, z) -> x * y / z
      ...> end <<~ [5, 2]
      ...>     <<~ [100, 50]
      ...> ~> fn x -> x + 1 end
      [6.0, 11.0, 3.0, 5.0, 11.0, 21.0, 5.0, 9.0]
      iex> import Realm.Functor, only: [<~: 2]
      ...> fn(a, b, c, d) -> a * b - c + d end <~ [1, 2] <<~ [3, 4] <<~ [5, 6] <<~ [7, 8]
      [5, 6, 4, 5, 6, 7, 5, 6, 8, 9, 7, 8, 10, 11, 9, 10]
  """
  @spec provide(Apply.t(), Apply.t()) :: Apply.t()
  def provide(funs, apply), do: funs |> Functor.map(&curry/1) |> Apply.Algebra.ap(apply)
  defdelegate funs <<~ apply, to: __MODULE__, as: :provide

  @doc """
  Same as `convey/2`, but with all functions curried.
  ## Examples
      iex> [1, 2, 3] ~>> [fn x -> x + 1 end, fn y -> y * 10 end]
      [2, 10, 3, 20, 4, 30]
      iex> import Realm.Functor
      ...>
      ...> [100, 50]
      ...> ~>> ([5, 2]     # Note the bracket
      ...> ~>> ([100, 200] # on both `Apply` lines
      ...> ~> fn(x, y, z) -> x * y / z end))
      [5.0, 10.0, 2.0, 4.0, 10.0, 20.0, 4.0, 8.0]
  """
  @spec supply(Apply.t(), Apply.t()) :: Apply.t()
  def supply(apply, funs), do: Apply.convey(apply, Functor.map(funs, &curry/1))
  defdelegate apply ~>> funs, to: __MODULE__, as: :supply
end
