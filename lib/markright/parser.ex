defmodule Markright.Parser do
  @moduledoc """
  The default behaviour for all the parsers.
  """
  @callback to_ast(String.t, Function.t, List.t) :: List.t | Tuple.t
end
