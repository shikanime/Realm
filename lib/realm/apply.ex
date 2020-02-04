defprotocol Realm.Apply do
  @moduledoc """
  An extension of `Realm.Functor`, `Apply` provides a way to _apply_ arguments
  to functions when both are apply in the same kind of container. This can be
  seen as running function application "in a context".
  For a nice, illustrated introduction,
  see [Functors, Applicatives, And Monads In Pictures](http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html).
  ## Graphically
  If function application looks like this
      data |> function == result
  and a functor looks like this
      %Container<data> ~> function == %Container<result>
  then an apply looks like
      %Container<data> ~>> %Container<function> == %Container<result>
  which is similar to function application inside containers, plus the ability to
  attach special effects to applications.
                 data --------------- function ---------------> result
      %Container<data> --- %Container<function> ---> %Container<result>
  This lets us do functorial things like
  * continue applying values to a curried function resulting from a `Realm.Functor.map/2`
  * apply multiple functions to multiple arguments (with lists)
  * propogate some state (like [`Nothing`](https://hexdocs.pm/algae/Algae.Maybe.Nothing.html#content)
  in [`Algae.Maybe`](https://hexdocs.pm/algae/Algae.Maybe.html#content))
  but now with a much larger number of arguments, reuse partially applied functions,
  and run effects with the function container as well as the data container.
  ## Examples
      iex> ap([fn x -> x + 1 end, fn y -> y * 10 end], [1, 2, 3])
      [2, 3, 4, 10, 20, 30]
      iex> [100, 200]
      ...> |> Realm.Functor.map(curry(fn)(x, y, z) -> x * y / z end)
      ...> |> provide([5, 2])
      ...> |> provide([100, 50])
      [5.0, 10.0, 2.0, 4.0, 10.0, 20.0, 4.0, 8.0]
      # ↓                          ↓
      # 100 * 5 / 100          200 * 5 / 50
      iex> import Realm.Functor
      ...>
      ...> [100, 200]
      ...> ~> fn(x, y, z) ->
      ...>   x * y / z
      ...> end <<~ [5, 2]
      ...>     <<~ [100, 50]
      [5.0, 10.0, 2.0, 4.0, 10.0, 20.0, 4.0, 8.0]
      # ↓                          ↓
      # 100 * 5 / 100          200 * 5 / 50
      %Algae.Maybe.Just{just: 42}
      ~> fn(x, y, z) ->
        x * y / z
      end <<~ %Algae.Maybe.Nothing{}
          <<~ %Algae.Maybe.Just{just: 99}
      #=> %Algae.Maybe.Nothing{}
  ## `convey` vs `ap`
  `convey` and `ap` essentially associate in opposite directions. For example,
  large data is _usually_ more efficient with `ap`, and large numbers of
  functions are _usually_ more efficient with `convey`.
  It's also more consistent consistency. In Elixir, we like to think of a "subject"
  being piped through a series of transformations. This places the function argument
  as the second argument. In `Realm.Functor`, this was of little consequence.
  However, in `Apply`, we're essentially running superpowered function application.
  `ap` is short for `apply`, as to not conflict with `Kernel.apply/2`, and is meant
  to respect a similar API, with the function as the first argument. This also reads
  nicely when piped, as it becomes `[funs] |> ap([args1]) |> ap([args2])`,
  which is similar in structure to `fun.(arg2).(arg1)`.
  With potentially multiple functions being applied over potentially
  many arguments, we need to worry about ordering. `convey` not only flips
  the order of arguments, but also who is in control of ordering.
  `convey` typically runs each function over all arguments (`first_fun ⬸ all_args`),
  and `ap` runs all functions for each element (`first_arg ⬸ all_funs`).
  This may change the order of results, and is a feature, not a bug.
      iex> [1, 2, 3]
      ...> |> Realm.Apply.convey([&(&1 + 1), &(&1 * 10)])
      [
        2, 10, # [(1 + 1), (1 * 10)]
        3, 20, # [(2 + 1), (2 * 10)]
        4, 30  # [(3 + 1), (3 * 10)]
      ]
      iex> [&(&1 + 1), &(&1 * 10)]
      ...> |> ap([1, 2, 3])
      [
        2,  3,  4, # [(1 + 1),  (2 + 1),  (3 + 1)]
        10, 20, 30 # [(1 * 10), (2 * 10), (3 * 10)]
      ]
  ## Type Class
  An instance of `Realm.Apply` must also implement `Realm.Functor`,
  and define `Realm.Apply.convey/2`.
      Functor  [map/2]
         ↓
       Apply   [convey/2]
  """

  @doc """
  Pipe arguments to functions, when both are apply in the same
  type of data structure.
  ## Examples
      iex> [1, 2, 3]
      ...> |> Apply.convey([fn x -> x + 1 end, fn y -> y * 10 end])
      [2, 10, 3, 20, 4, 30]
  """
  @spec convey(Apply.t(), Apply.t()) :: Apply.t()
  def convey(apply, func)
end

defmodule Realm.Apply.Algebra do
  alias Realm.{Apply, Functor}
  import Quark.Curry

  @doc """
  Alias for `convey/2`.
  Why "hose"?
  * Pipes (`|>`) are application with arguments flipped
  * `ap/2` is like function application "in a context"
  * The opposite of `ap` is a contextual pipe
  * `hose`s are a kind of flexible pipe
  Q.E.D.
  ![](http://s2.quickmeme.com/img/fd/fd0baf5ada879021c32129fc7dea679bd7666e708df8ca8ca536da601ea3d29e.jpg)
  ## Examples
      iex> [1, 2, 3]
      ...> |> hose([fn x -> x + 1 end, fn y -> y * 10 end])
      [2, 10, 3, 20, 4, 30]
  """
  @spec hose(Apply.t(), Apply.t()) :: Apply.t()
  def hose(apply, func), do: Apply.convey(apply, func)

  @doc """
  Reverse arguments and sequencing of `convey/2`.
  Conceptually this makes operations happen in
  a different order than `convey/2`, with the left-side arguments (functions) being
  run on all right-side arguments, in that order. We're altering the _sequencing_
  of function applications.
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> ap([fn x -> x + 1 end, fn y -> y * 10 end], [1, 2, 3])
      [2, 3, 4, 10, 20, 30]
      # For comparison
      iex> Apply.convey([1, 2, 3], [fn x -> x + 1 end, fn y -> y * 10 end])
      [2, 10, 3, 20, 4, 30]
      iex> [100, 200]
      ...> |> Realm.Functor.map(curry(fn)(x, y, z) -> x * y / z end)
      ...> |> ap([5, 2])
      ...> |> ap([100, 50])
      [5.0, 10.0, 2.0, 4.0, 10.0, 20.0, 4.0, 8.0]
      # ↓                          ↓
      # 100 * 5 / 100          200 * 5 / 50
  """
  @spec ap(Apply.t(), Apply.t()) :: Apply.t()
  def ap(func, apply) do
    lift(apply, func, fn arg, fun -> fun.(arg) end)
  end

  @doc """
  Sequence actions, replacing the first/previous values with the last argument
  This is essentially a sequence of actions forgetting the first argument
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> [1, 2, 3]
      ...> |> then([4, 5, 6])
      ...> |> then([7, 8, 9])
      [
        7, 8, 9,
        7, 8, 9,
        7, 8, 9,
        7, 8, 9,
        7, 8, 9,
        7, 8, 9,
        7, 8, 9,
        7, 8, 9,
        7, 8, 9
      ]
      iex> import Realm.Apply.Algebra
      ...> {1, 2, 3} |> then({4, 5, 6}) |> then({7, 8, 9})
      {12, 15, 9}
  """
  @spec then(Apply.t(), Apply.t()) :: Apply.t()
  def then(left, right), do: over(&Quark.constant(&2, &1), left, right)

  @doc """
  Sequence actions, replacing the last argument with the first argument's values
  This is essentially a sequence of actions forgetting the second argument
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> [1, 2, 3]
      ...> |> following([3, 4, 5])
      ...> |> following([5, 6, 7])
      [
        1, 1, 1, 1, 1, 1, 1, 1, 1,
        2, 2, 2, 2, 2, 2, 2, 2, 2,
        3, 3, 3, 3, 3, 3, 3, 3, 3
      ]
      iex> import Realm.Apply.Algebra
      ...> {1, 2, 3} |> following({4, 5, 6}) |> following({7, 8, 9})
      {12, 15, 3}
  """
  @spec following(Apply.t(), Apply.t()) :: Apply.t()
  def following(left, right), do: lift(right, left, &Quark.constant(&2, &1))

  @doc """
  Extends `Functor.map/2` to apply arguments to a binary function
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> lift([1, 2], [3, 4], &+/2)
      [4, 5, 5, 6]
      iex> import Realm.Apply.Algebra
      ...> [1, 2]
      ...> |> lift([3, 4], &*/2)
      [3, 6, 4, 8]
  """
  @spec lift(Apply.t(), Apply.t(), fun()) :: Apply.t()
  def lift(a, b, fun) do
    a
    |> Functor.map(curry(fun))
    |> (fn f -> Apply.convey(b, f) end).()
  end

  @doc """
  Extends `lift` to apply arguments to a ternary function
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> lift([1, 2], [3, 4], [5, 6], fn(a, b, c) -> a * b - c end)
      [-2, -3, 1, 0, -1, -2, 3, 2]
  """
  @spec lift(Apply.t(), Apply.t(), Apply.t(), fun()) :: Apply.t()
  def lift(a, b, c, fun), do: a |> lift(b, fun) |> ap(c)

  @doc """
  Extends `lift` to apply arguments to a quaternary function
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> lift([1, 2], [3, 4], [5, 6], [7, 8], fn(a, b, c, d) -> a * b - c + d end)
      [5, 6, 4, 5, 8, 9, 7, 8, 6, 7, 5, 6, 10, 11, 9, 10]
  """
  @spec lift(Apply.t(), Apply.t(), Apply.t(), Apply.t(), fun()) :: Apply.t()
  def lift(a, b, c, d, fun), do: a |> lift(b, c, fun) |> ap(d)

  @doc """
  Extends `over` to apply arguments to a binary function
  ## Examples
      iex> over(&+/2, [1, 2], [3, 4])
      [4, 5, 5, 6]
      iex> (&*/2)
      ...> |> over([1, 2], [3, 4])
      [3, 4, 6, 8]
  """
  @spec over(fun(), Apply.t(), Apply.t()) :: Apply.t()
  def over(fun, a, b), do: a |> Functor.map(curry(fun)) |> ap(b)

  @doc """
  Extends `over` to apply arguments to a ternary function
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> fn(a, b, c) -> a * b - c end
      ...> |> over([1, 2], [3, 4], [5, 6])
      [-2, -3, -1, -2, 1, 0, 3, 2]
  """
  @spec over(fun(), Apply.t(), Apply.t(), Apply.t()) :: Apply.t()
  def over(fun, a, b, c), do: fun |> over(a, b) |> ap(c)

  @doc """
  Extends `over` to apply arguments to a ternary function
  ## Examples
      iex> import Realm.Apply.Algebra
      ...> fn(a, b, c) -> a * b - c end
      ...> |> over([1, 2], [3, 4], [5, 6])
      [-2, -3, -1, -2, 1, 0, 3, 2]
  """
  @spec over(fun(), Apply.t(), Apply.t(), Apply.t(), Apply.t()) :: Apply.t()
  def over(fun, a, b, c, d), do: fun |> over(a, b, c) |> ap(d)
end

defimpl Realm.Apply, for: Function do
  use Quark
  def convey(g, f), do: fn x -> curry(f).(x).(curry(g).(x)) end
end

defimpl Realm.Apply, for: List do
  def convey(val_list, fun_list) when is_list(fun_list) do
    Enum.flat_map(val_list, fn val ->
      Enum.map(fun_list, fn fun -> fun.(val) end)
    end)
  end
end

# Contents must be semigroups
defimpl Realm.Apply, for: Tuple do
  alias Realm.Semigroup

  def convey({v, w}, {a, fun}) do
    {Semigroup.append(v, a), fun.(w)}
  end

  def convey({v, w, x}, {a, b, fun}) do
    {Semigroup.append(v, a), Semigroup.append(w, b), fun.(x)}
  end

  def convey({v, w, x, y}, {a, b, c, fun}) do
    {Semigroup.append(v, a), Semigroup.append(w, b), Semigroup.append(x, c), fun.(y)}
  end

  def convey({v, w, x, y, z}, {a, b, c, d, fun}) do
    {
      Semigroup.append(a, v),
      Semigroup.append(b, w),
      Semigroup.append(c, x),
      Semigroup.append(d, y),
      fun.(z)
    }
  end

  def convey(left, right) when tuple_size(left) == tuple_size(right) do
    last_index = tuple_size(left) - 1

    left
    |> Tuple.to_list()
    |> Enum.zip(Tuple.to_list(right))
    |> Enum.with_index()
    |> Enum.map(fn
      {{arg, fun}, ^last_index} -> fun.(arg)
      {{left, right}, _} -> Semigroup.append(left, right)
    end)
    |> List.to_tuple()
  end
end
