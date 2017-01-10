defmodule Markright.Continuation do
  @moduledoc """
  The tuple, that is being returned from any call to `Parser.to_ast/3`.
  """

  ##############################################################################

  @typedoc """
  The continuation, returned from any call to `Parser.to_ast/3`.
  """
  @type t :: %Markright.Continuation{}

  ##############################################################################

  @fields [ast: {:nil, %{}, ""}, tail: ""]

  def fields, do: @fields

  defstruct @fields

  ##############################################################################

  defmacro __using__(_opts) do
    quote do
      alias Markright.Continuation, as: C
    end
  end

  ##############################################################################

  import Markright.Guards

  ##############################################################################

  def last?(%Markright.Continuation{tail: ""} = _data), do: true
  def last?(%Markright.Continuation{} = _data), do: false

  def empty?(%Markright.Continuation{ast: {:nil, _, _}} = _data), do: true
  def empty?(%Markright.Continuation{} = _data), do: false

  def last!(tag, opts, value), do: last!({tag, opts, value})
  def last!({tag, opts, value}), do: %Markright.Continuation{ast: {tag, opts, value}}

  def continue(%Markright.Continuation{} = data, {tag, opts}),
    do: %Markright.Continuation{data | ast: {tag, opts, unlist(data.ast)}}
  def continue(ast, {tag, opts}) when is_tuple(ast) or is_list(ast),
    do: %Markright.Continuation{ast: {tag, opts, ast}}
  def continue(ast, tail) when (is_tuple(ast) or is_list(ast)) and is_binary(tail),
    do: %Markright.Continuation{ast: unlist(ast), tail: tail}

  ##############################################################################

  @spec callback(Markright.Continuation.t, Function.t | Markright.Continuation.t | nil) :: Markright.Continuation.t
  def callback(data, fun \\ nil)

  def callback(%Markright.Continuation{} = data, %Markright.Continuation{} = result),
    do: Map.merge(data, result)
  def callback(%Markright.Continuation{} = data, fun) when is_function(fun, 1),
    do: callback(data, fun.(data))
  def callback(%Markright.Continuation{ast: ast, tail: tail} = data, fun) when is_function(fun, 2),
    do: callback(data, fun.(ast, tail))
  def callback(%Markright.Continuation{} = data, _), do: data
end
