defmodule Realm do
  import Kernel, except: [!=: 2, ==: 2]
  alias Realm.{Semigroup, Setoid, Arrow, Ord}

  def a <> b, do: Semigroup.Class.append(a, b)

  def a == b, do: Setoid.equivalent?(a, b)
  def a != b, do: Setoid.nonequivalent?(a, b)

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
  def g <|> f, do: Semigroupoid.Class.compose(g, f)

  @doc """
  Composition operator "the pipe way". Alias for `pipe_compose/2`.
  ## Examples
      iex> times_ten_plus_one =
      ...>       fn y -> y * 10 end
      ...>   <~> fn x -> x + 1  end
      ...>
      ...> times_ten_plus_one.(5)
      51
  """
  @spec Semigroupoid.t() <~> any() :: Semigroupoid.t()
  def f <~> g, do: Semigroupoid.Class.compose(g, f)

  @doc """
  Operator alias for `product/2`.
  ## Examples
      iex> arr = fn x -> x - 10 end ^^^ fn y -> y <> "!" end
      ...> arr.({42, "Hi"})
      {32, "Hi!"}
      iex> {42, "Hi"} |> (fn x -> x - 10 end ^^^ fn y -> y <> "!" end).()
      {32, "Hi!"}
  """
  @spec Arrow.t() ^^^ Arrow.t() :: Arrow.t()
  def a ^^^ b, do: Arrow.product(a, b)

  @doc """
  Operator alias for `fanout/2`.
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
  def a &&& b, do: Arrow.fanout(a, b)

  def a > b, do: Ord.greater?(a, b)
  def a < b, do: Ord.lesser?(a, b)

  @doc """
  Determine if an element is `:lesser` or `:equal` to another.
  ## Examples
      iex> use Ord
      ...> 1 <= 2
      true
      ...> [] <= [1, 2, 3]
      false
      ...> [1] <= [1, 2, 3]
      true
      ...> [4] <= [1, 2, 3]
      false
  """
  # credo:disable-for-next-line Credo.Check.Warning.OperationOnSameValues
  @spec Ord.t() <= Ord.t() :: boolean()
  def a <= b, do: Ord.compare(a, b) != :greater

  @doc """
  Determine if an element is `:greater` or `:equal` to another.
  ## Examples
      iex> use Ord
      ...> 2 >= 1
      true
      ...> [1, 2, 3] >= []
      true
      ...> [1, 2, 3] >= [1]
      true
      ...> [1, 2, 3] >= [4]
      false
  """
  # credo:disable-for-next-line Credo.Check.Warning.OperationOnSameValues
  @spec Ord.t() >= Ord.t() :: boolean()
  def a >= b, do: Ord.compare(a, b) != :lesser
end
