defmodule Realm.Arrow do
  @type t :: fun()

  @doc """
  Take two arguments (as a 2-tuple), and run one function on the left side (first element),
  and run a different function on the right side (second element).
        ┌------> f.(a) = x -------┐
        |                         v
      {a, b}                    {x, y}
        |                         ^
        └------> g.(b) = y -------┘
  ## Examples
      iex> product(&(&1 - 10), &(&1 <> "!")).({42, "Hi"})
      {32, "Hi!"}
  """
  @spec product(Realm.Arrow.t(), Realm.Arrow.t()) :: Realm.Arrow.t()
  def product(f, g), do: first(f) |> Semigroupoid.Class.compose(second(g))

  @doc """
  Swap positions of elements in a tuple.
  ## Examples
      iex> swap({1, 2})
      {2, 1}
  """
  @spec swap({any(), any()}) :: {any(), any()}
  def swap({x, y}), do: {y, x}

  @doc """
  Target the first element of a tuple.
  ## Examples
      iex> first(fn x -> x * 50 end).({1, 1})
      {50, 1}
  """
  @spec first(Realm.Arrow.t()) :: Realm.Arrow.t()
  def first(arrow) do
    Realm.Arrow.Class.arrowize(arrow, fn {x, y} ->
      {x |> Realm.Semigroupoid.pipe(arrow), y |> Realm.Semigroupoid.pipe(id_arrow(arrow))}
    end)
  end

  @doc """
  Target the second element of a tuple.
  ## Examples
      iex> second(fn x -> x * 50 end).({1, 1})
      {1, 50}
  """
  @spec second(Realm.Arrow.t()) :: Realm.Arrow.t()
  def second(arrow) do
    Realm.Arrow.Class.arrowize(arrow, fn {x, y} ->
      {x |> Realm.Semigroupoid.pipe(id_arrow(arrow)), y |> Realm.Semigroupoid.pipe(arrow)}
    end)
  end

  @doc """
  The identity function lifted into an arrow of the correct type.
  ## Examples
      iex> id_arrow(fn -> nil end).(99)
      99
  """
  @spec id_arrow(Realm.Arrow.t()) :: (any() -> Realm.Arrow.t())
  def id_arrow(arrow), do: Realm.Arrow.Class.arrowize(arrow, &Quark.id/1)

  @doc """
  Duplicate incoming data into both halves of a 2-tuple, and run one function
  on the left copy, and a different function on the right copy.
               ┌------> f.(a) = x ------┐
               |                        v
      a ---> split = {a, a}           {x, y}
               |                        ^
               └------> g.(a) = y ------┘
  ## Examples
      iex> Realm.Semigroupoid.Realm.Semigroupoid.pipe(42, fanout(&(&1 - 10), &(inspect(&1) <> "!")))
      {32, "42!"}
  """
  @spec fanout(Realm.Arrow.t(), Realm.Arrow.t()) :: Realm.Arrow.t()
  def fanout(f, g) do
    f
    |> Realm.Arrow.Class.arrowize(&split/1)
    |> Realm.Semigroupoid.Class.compose(Realm.Arrow.product(f, g))
  end

  @doc """
  Copy a single value into both positions of a 2-tuple.
  This is useful is you want to run functions on the input separately.
  ## Examples
      iex> split(42)
      {42, 42}
      iex> import Realm.Semigroupoid, only: [<~>: 2]
      ...> 5
      ...> |> split()
      ...> |> (second(fn x -> x - 2 end)
      ...> <~> first(fn y -> y * 10 end)
      ...> <~> second(&inspect/1)).()
      {50, "3"}
      iex> use Realm.Arrow
      ...> 5
      ...> |> split()
      ...> |> Realm.Semigroupoid.pipe(second(fn x -> x - 2 end))
      ...> |> Realm.Semigroupoid.pipe(first(fn y -> y * 10 end))
      ...> |> Realm.Semigroupoid.pipe(second(&inspect/1))
      {50, "3"}
  """
  @spec split(any()) :: {any(), any()}
  def split(x), do: {x, x}

  @doc """
  Merge two tuple values with a combining function.
  ## Examples
      iex> unsplit({1, 2}, &+/2)
      3
  """
  @spec unsplit({any(), any()}, (any(), any() -> any())) :: any()
  def unsplit({x, y}, combine), do: combine.(x, y)

  @doc """
  Switch the associativity of a nested tuple. Helpful since many arrows act
  on a subset of a tuple, and you may want to move portions in and out of that stream.
  ## Examples
      iex> reassociate({1, {2, 3}})
      {{1, 2}, 3}
      iex> reassociate({{1, 2}, 3})
      {1, {2, 3}}
  """
  @spec reassociate({any(), {any(), any()}} | {{any(), any()}, any()}) ::
          {{any(), any()}, any()} | {any(), {any(), any()}}
  def reassociate({{a, b}, c}), do: {a, {b, c}}
  def reassociate({a, {b, c}}), do: {{a, b}, c}

  @doc """
  Compose a function (left) with an arrow (right) to produce a new arrow.
  ## Examples
      iex> f = precompose(
      ...>   fn x -> x + 1 end,
      ...>   Realm.Arrow.Class.arrowize(fn _ -> nil end, fn y -> y * 10 end)
      ...> )
      ...> f.(42)
      430
  """
  @spec precompose(fun(), Realm.Arrow.t()) :: Realm.Arrow.t()
  def precompose(fun, arrow),
    do: Realm.Arrow.Class.arrowize(arrow, fun) |> Realm.Semigroupoid.Class.compose(arrow)

  @doc """
  Compose an arrow (left) with a function (right) to produce a new arrow.
  ## Examples
      iex> f = postcompose(
      ...>   Realm.Arrow.Class.arrowize(fn _ -> nil end, fn x -> x + 1 end),
      ...>   fn y -> y * 10 end
      ...> )
      ...> f.(42)
      430
  """
  @spec precompose(Realm.Arrow.t(), fun()) :: Realm.Arrow.t()
  def postcompose(arrow, fun),
    do: arrow |> Realm.Semigroupoid.Class.compose(Realm.Arrow.Class.arrowize(arrow, fun))
end

defprotocol Realm.Realm.Arrow.Class do
  @doc """
  Lift a function into an arrow, much like how `of/2` does with data.
  Essentially a label for composing functions end-to-end, where instances
  may have their own special idea of what composition means. The simplest example
  is a regular function. Others are possible, such as Kleisli arrows.
  ## Examples
      iex> use Realm.Arrow
      ...> times_ten = Realm.Arrow.Class.arrowize(fn -> nil end, &(&1 * 10))
      ...> 5 |> Realm.Semigroupoid.pipe(times_ten)
      50
  """
  @spec arrowize(Realm.Arrow.t(), fun()) :: Realm.Arrow.t()
  def arrowize(arrow, fun)
end

defimpl Realm.Realm.Arrow.Class, for: Function do
  use Quark

  def arrowize(_, fun), do: curry(fun)
  def first(arrow), do: fn {target, unchanged} -> {arrow.(target), unchanged} end
end
