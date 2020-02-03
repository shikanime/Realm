import Kernel, except: [==: 2, !=: 2, >: 2, <: 2, <=: 2, >=: 2, <>: 2, apply: 2]

defmodule Realm do
  alias Realm.{Semigroupoid, Semigroup, Arrow, Apply, Ord, Setoid, Functor}

  @doc false
  defmacro __using__(options) do
    except =
      cond do
        Keyword.get(options, :only_operators) ->
          [
            compose: 2,
            flow_compose: 2,
            product: 2,
            fanout: 2,
            lesser?: 2,
            greater?: 2,
            at_most?: 2,
            at_least?: 2,
            equal?: 2,
            nonequivalent?: 2,
            lift: 2,
            over: 2,
            provide: 2,
            supply: 2
          ]

        Keyword.get(options, :skip_operators) ->
          [
            <|>: 2,
            <~>: 2,
            <>: 2,
            ^^^: 2,
            &&&: 2,
            <: 2,
            >: 2,
            <=: 2,
            >=: 2,
            ==: 2,
            !=: 2,
            ~>: 2,
            <~: 2,
            <<~: 2,
            ~>>: 2
          ]

        :else ->
          []
      end

    quote do
      import Kernel, except: [<>: 2, <: 2, >: 2, <=: 2, >=: 2, ==: 2, !=: 2]
      import Realm, except: unquote(except)
    end
  end

  @doc """
  Composition operator "the math way". Alias for `compose/2`.
  ## Examples
      iex> times_ten_plus_one = compose(fn x -> x + 1  end, fn y -> y * 10 end)
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec compose(Semigroupoid.t(), any()) :: Semigroupoid.t()
  def compose(g, f), do: Semigroupoid.compose(g, f)

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
  def g <|> f, do: compose(g, f)

  @doc """
  Composition operator "the pipe way". Alias for `compose/2`.
  ## Examples
      iex> times_ten_plus_one = flow_compose(fn y -> y * 10 end, fn x -> x + 1  end)
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec flow_compose(Semigroupoid.t(), any()) :: Semigroupoid.t()
  def flow_compose(f, g), do: Semigroupoid.compose(g, f)

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
  def f <~> g, do: flow_compose(f, g)

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
      ...> append([1, 2, 3], [4, 5, 6]) |> append([7, 8, 9])
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      iex> use Realm.Semigroup
      ...> append("foo", " ") |> append("bar")
      "foo bar"
  """
  @spec append(Semigroup.t(), Semigroup.t()) :: Semigroupoid.t()
  def append(left, right), do: Semigroup.append(left, right)

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
  @spec Semigroup.t() <> Semigroup.t() :: Semigroupoid.t()
  def left <> right, do: append(left, right)

  @doc """
  Take two arguments (as a 2-tuple), and run one function on the left side (first element),
  and run a different function on the right side (second element).
        ┌------> f.(a) = x -------┐
        |                         v
      {a, b}                    {x, y}
        |                         ^
        └------> g.(b) = y -------┘
  ## Examples
      iex> arr = product(fn x -> x - 10 end, fn y -> y <> "!" end)
      ...> arr.({42, "Hi"})
      {32, "Hi!"}
      iex> {42, "Hi"} |> product(fn x -> x - 10 end, fn y -> y <> "!" end).()
      {32, "Hi!"}
  """
  @spec product(Arrow.t(), Arrow.t()) :: Arrow.t()
  def product(f, g), do: Arrow.Algebra.first(f) <~> Arrow.Algebra.second(g)

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
  @spec Arrow.t() ^^^ Arrow.t() :: Arrow.t()
  def left ^^^ right, do: product(left, right)

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
      ...>   fanout(fn x -> x - 10 end, fn y -> inspect(y) <> "!" end)
      ...>   |> fanout(fn z -> inspect(z) <> "?" end)
      ...>   |> fanout(fn d -> inspect(d) <> inspect(d) end)
      ...>   |> fanout(fn e -> e / 2 end)
      ...>
      ...> fanned.(42)
      {{{{32, "42!"}, "42?"}, "4242"}, 21.0}
  """
  @spec fanout(Arrow.t(), Arrow.t()) :: Arrow.t()
  def fanout(f, g), do: f |> Arrow.arrowize(&Arrow.Algebra.split/1) <~> (f ^^^ g)

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
  @spec Arrow.t() &&& Arrow.t() :: Arrow.t()
  def left &&& right, do: fanout(left, right)

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

  @doc """
  Determine if an element is `:greater` than another.
  ## Examples
      iex> 1 > 1
      false
      iex> 1.1 > 1
      true
  """
  @spec Ord.t() > Ord.t() :: boolean()
  def left > right, do: greater?(left, right)

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

  @doc """
  Determine if an element is `:lesser` than another.
  ## Examples
      iex> 1 < 1
      false
      iex> 1 < 1.1
      true
  """
  @spec Ord.t() < Ord.t() :: boolean()
  def left < right, do: lesser?(left, right)

  @doc """
  Determine if an element is `:lesser` or `:equal` to another.
  ## Examples
      iex> use Realm.Ord
      ...> at_most?(1, 2)
      true
      ...> at_most?([], [1, 2, 3])
      false
      ...> at_most?([1], [1, 2, 3])
      true
      ...> at_most?([4], [1, 2, 3])
      false
  """
  @spec at_most?(Ord.t(), Ord.t()) :: boolean()
  def at_most?(left, right), do: Ord.compare(left, right) != :greater

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
  def left <= right, do: at_most?(left, right)

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
  @spec at_least?(Ord.t(), Ord.t()) :: boolean()
  def at_least?(left, right), do: Ord.compare(left, right) != :lesser

  @doc """
  Determine if an element is `:greater` or `:equal` to another.
  ## Examples
      iex> use Realm.Ord
      ...> at_least?(2,  1)
      true
      ...> at_least?([1, 2, 3], [])
      true
      ...> at_least?([1, 2, 3], [1])
      true
      ...> at_least?([1, 2, 3], [4])
      false
  """
  @spec Ord.t() >= Ord.t() :: boolean()
  def left >= right, do: at_least?(left, right)

  @doc """
  Determine if an element is equal to another.
  ## Examples
      iex> use Realm.Ord
      ...> equal?(2, 1)
      false
      ...> equal?(1, 1)
      true
  """
  @spec equal?(Setoid.t(), Setoid.t()) :: boolean()
  def equal?(left, right), do: Setoid.equivalent?(left, right)

  @doc """
  Determine if an element is equal to another.
  ## Examples
      iex> use Realm.Ord
      ...> 2 == 1
      false
      ...> 1 == 1
      true
  """
  @spec Setoid.t() == Setoid.t() :: boolean()
  def left == right, do: equal?(left, right)

  @doc """
  The opposite of `equivalent?/2`.
  ## Examples
      iex> nonequivalent?(1, 2)
      true
  """
  @spec nonequivalent?(Setoid.t(), Setoid.t()) :: boolean()
  def nonequivalent?(left, right), do: not Setoid.equivalent?(left, right)

  @doc """
  The opposite of `equivalent?/2`.
  ## Examples
      iex> 1 != 2
      true
  """
  @spec Setoid.t() != Setoid.t() :: boolean()
  def left != right, do: nonequivalent?(left, right)

  @doc ~S"""
  `map/2` but with the function automatically curried
  ## Examples
      iex> lift([1, 2, 3], fn x -> x + 55 end)
      ...> |> lift(fn y -> y * 10 end)
      [560, 570, 580]
      iex> lift([1, 2, 3], fn(x, y) -> x + y end)
      ...> |> List.first()
      ...> |> apply([9])
      10
  """
  @spec lift(Functor.t(), fun()) :: Functor.t()
  def lift(functor, fun), do: Functor.map(functor, Quark.Curry.curry(fun))

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
  @spec Functor.t() ~> fun() :: Functor.t()
  def functor ~> fun, do: lift(functor, fun)

  @doc """
  `lift/2` but with arguments flipped.
      iex> lift(fn x -> x + 5 end, [1,2,3])
      [6, 7, 8]
  Note that the mnemonic is flipped from `|>`, and combinging directions can
  be confusing. It's generally recommended to use `~>`, or to keep `<~` on
  the same line both of it's arguments:
      iex> over(fn(x, y) -> x + y end, [1, 2, 3])
      ...> |> List.first()
      ...> |> apply([9])
      10
  ...or in an expression that's only pointing left:
      iex> over(fn y -> y * 10 end, fn x -> x + 55 end)
      ...> |> over([1, 2, 3])
      [560, 570, 580]
  """
  @spec over(fun(), Functor.t()) :: Functor.t()
  def over(fun, functor), do: lift(functor, fun)

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
  @spec fun() <~ Functor.t() :: Functor.t()
  def fun <~ functor, do: over(fun, functor)

  @doc """
  Same as `ap/2`, but with all functions curried.
  ## Examples
      iex> [fn x -> x + 1 end, fn y -> y * 10 end] <<~ [1, 2, 3]
      [2, 3, 4, 10, 20, 30]
      iex> import Realm.Functor
      ...>
      ...> [100, 200]
      ...> ~> fn(x, y, z) -> x * y / z end
      ...> |> provide([5, 2])
      ...> |> provide([100, 50])
      ...> |> provide(fn x -> x + 1 end)
      [6.0, 11.0, 3.0, 5.0, 11.0, 21.0, 5.0, 9.0]
      iex> import Realm.Functor, only: [<~: 2]
      ...> fn(a, b, c, d) -> a * b - c + d end <~ [1, 2] |> provide([3, 4]) |> provide([5, 6]) |> provide([7, 8])
      [5, 6, 4, 5, 6, 7, 5, 6, 8, 9, 7, 8, 10, 11, 9, 10]
  """
  @spec provide(Apply.t(), Apply.t()) :: Apply.t()
  def provide(funs, apply),
    do: funs |> Functor.map(&Quark.Curry.curry/1) |> Apply.Algebra.ap(apply)

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
  @spec Apply.t() <<~ Apply.t() :: Apply.t()
  def funs <<~ apply, do: provide(funs, apply)

  @doc """
  Same as `convey/2`, but with all functions curried.
  ## Examples
      iex> [1, 2, 3] ~>> [fn x -> x + 1 end, fn y -> y * 10 end]
      [2, 10, 3, 20, 4, 30]
      iex> import Realm.Functor
      ...>
      ...> [100, 50]
      ...> |> supply([5, 2]     # Note the bracket
      ...> |> supply([100, 200] # on both `Apply` lines
      ...> ~> fn(x, y, z) -> x * y / z end))
      [5.0, 10.0, 2.0, 4.0, 10.0, 20.0, 4.0, 8.0]
  """
  @spec supply(Apply.t(), Apply.t()) :: Apply.t()
  def supply(apply, funs), do: Apply.convey(apply, Functor.map(funs, &Quark.Curry.curry/1))

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
  @spec Apply.t() ~>> Apply.t() :: Apply.t()
  def apply ~>> funs, do: supply(apply, funs)
end
