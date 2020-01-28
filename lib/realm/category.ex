defmodule Realm.Category do
  @type t :: any()
end

defprotocol Relam.Category.Class do
  @spec identity(Category.t()) :: Category.t()
  def identity(category)
end

defimpl Relam.Category.Class, for: Function do
  def identity(_), do: &Quark.id/1
end
