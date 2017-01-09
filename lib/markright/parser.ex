defmodule Markright.Parser do
  @moduledoc """
  The default behaviour for all the parsers.
  """
  @callback to_ast(String.t, Function.t, Map.t) :: Markright.Continuation.t
end