import Realm.Semigroupoid.Algebra

defprotocol Realm.Arrow do
  @moduledoc """
  Arrows abstract the idea of computations, potentially with a context.
  Arrows are in fact an abstraction above monads, and can be used both to
  express all other type classes in Realm. They also enable some nice
  flow-based reasoning about computation.
  For a nice illustrated explination,
  see [Haskell/Understanding arrows](https://en.wikibooks.org/wiki/Haskell/Understanding_arrows)
  Arrows let you think diagrammatically, and is a powerful way of thinking
  about flow programming, concurrency, and more.
                   ┌---> f --------------------------┐
                   |                                 v
      input ---> split                            unsplit ---> result
                   |                                 ^
                   |              ┌--- h ---┐        |
                   |              |         v        |
                   └---> g ---> split     unsplit ---┘
                                  |         ^
                                  └--- i ---┘
  ## Type Class
  An instance of `Realm.Arrow` must also implement `Realm.Category`,
  and define `Realm.Arrow.arrowize/2`.
      Semigroupoid  [compose/2, apply/2]
          ↓
       Category     [identity/1]
          ↓
        Arrow       [arrowize/2]
  """

  @doc """
  Lift a function into an arrow, much like how `of/2` does with data.
  Essentially a label for composing functions end-to-end, where instances
  may have their own special idea of what composition means. The simplest example
  is a regular function. Others are possible, such as Kleisli arrows.
  ## Examples
      iex> use Realm.Arrow
      ...> times_ten = arrowize(fn -> nil end, &(&1 * 10))
      ...> 5 |> Realm.pipe(times_ten)
      50
  """
  @spec arrowize(t(), fun()) :: t()
  def arrowize(sample, fun)
end

defmodule Realm.Arrow.Algebra do
  alias Realm.{Arrow, Semigroupoid}

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
      iex> import Realm.Arrow.Algebra
      ...> first(fn x -> x * 50 end).({1, 1})
      {50, 1}
  """
  @spec first(Arrow.t()) :: Arrow.t()
  def first(arrow) do
    Arrow.arrowize(arrow, fn {x, y} ->
      {x |> pipe(arrow), y |> pipe(id_arrow(arrow))}
    end)
  end

  @doc """
  Target the second element of a tuple.
  ## Examples
      iex> import Realm.Arrow.Algebra
      ...> second(fn x -> x * 50 end).({1, 1})
      {1, 50}
  """
  @spec second(Arrow.t()) :: Arrow.t()
  def second(arrow) do
    Arrow.arrowize(arrow, fn {x, y} ->
      {x |> pipe(id_arrow(arrow)), y |> pipe(arrow)}
    end)
  end

  @doc """
  The identity function lifted into an arrow of the correct type.
  ## Examples
      iex> id_arrow(fn -> nil end).(99)
      99
  """
  @spec id_arrow(Arrow.t()) :: (any() -> Arrow.t())
  def id_arrow(sample), do: Arrow.arrowize(sample, &Quark.id/1)

  @doc """
  Copy a single value into both positions of a 2-tuple.
  This is useful is you want to run functions on the input separately.
  ## Examples
      iex> import Realm.Arrow.Algebra
      ...> split(42)
      {42, 42}
      iex> import Realm.Arrow.Algebra
      ...> 5
      ...> |> split()
      ...> |> (second(fn x -> x - 2 end)
      ...> <~> first(fn y -> y * 10 end)
      ...> <~> second(&inspect/1)).()
      {50, "3"}
      iex> import Realm.Arrow.Algebra
      ...> import Realm.Semigroupoid.Algebra
      ...> 5
      ...> |> split()
      ...> |> pipe(second(fn x -> x - 2 end))
      ...> |> pipe(first(fn y -> y * 10 end))
      ...> |> pipe(second(&inspect/1))
      {50, "3"}
  """
  @spec split(any()) :: {any(), any()}
  def split(x), do: {x, x}

  @doc """
  Merge two tuple values with a combining function.
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> unsplit({1, 2}, &+/2)
      3
  """
  @spec unsplit({any(), any()}, (any(), any() -> any())) :: any()
  def unsplit({x, y}, fun), do: fun.(x, y)

  @doc """
  Switch the associativity of a nested tuple. Helpful since many arrows act
  on a subset of a tuple, and you may want to move portions in and out of that stream.
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> reassociate({1, {2, 3}})
      {{1, 2}, 3}
      iex> import Realm.Apply.Algebra
      ...> reassociate({{1, 2}, 3})
      {1, {2, 3}}
  """
  @spec reassociate({any(), {any(), any()}} | {{any(), any()}, any()}) ::
          {{any(), any()}, any()} | {any(), {any(), any()}}
  def reassociate({{a, b}, c}), do: {a, {b, c}}
  def reassociate({a, {b, c}}), do: {{a, b}, c}

  @doc """
  Compose a function (left) with an arrow (right) to produce a new arrow.
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> f = precompose(
      ...>   fn x -> x + 1 end,
      ...>   Arrow.arrowize(fn _ -> nil end, fn y -> y * 10 end)
      ...> )
      ...> f.(42)
      430
  """
  @spec precompose(fun(), Arrow.t()) :: Arrow.t()
  def precompose(fun, arrow), do: Semigroupoid.compose(Arrow.arrowize(arrow, fun), arrow)

  @doc """
  Compose an arrow (left) with a function (right) to produce a new arrow.
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> f = postcompose(
      ...>   Arrow.arrowize(fn _ -> nil end, fn x -> x + 1 end),
      ...>   fn y -> y * 10 end
      ...> )
      ...> f.(42)
      430
  """
  @spec postcompose(Arrow.t(), fun()) :: Arrow.t()
  def postcompose(arrow, fun), do: Semigroupoid.compose(arrow, Arrow.arrowize(arrow, fun))
end

defimpl Realm.Arrow, for: Function do
  use Quark

  def arrowize(_, fun), do: curry(fun)
  def first(arrow), do: fn {target, unchanged} -> {arrow.(target), unchanged} end
end
