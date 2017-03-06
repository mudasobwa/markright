defmodule Markright.Parsers.Code do
  @moduledoc ~S"""
  Parses the input for the inline code snippet.
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: code, tail: rest} <- astify(input, fun) do
      Markright.Utils.continuation(%C{ast: code, tail: rest}, {:code, opts, fun})
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, acc \\ Buf.empty())

  ##############################################################################

  defp astify(<<"`" :: binary, rest :: binary>>, _fun, acc),
    do: %C{ast: acc.buffer, tail: rest}

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
    do: astify(rest, fun, Buf.append(acc, letter))

  defp astify("", _fun, acc),
    do: %C{ast: acc.buffer, tail: ""}

  ##############################################################################
end
