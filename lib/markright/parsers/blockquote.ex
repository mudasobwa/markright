defmodule Markright.Parsers.Blockquote do
  @moduledoc ~S"""
  Parses the input for the blockquote block.

  ## Examples

      iex> input = "Hello
      ...> — world!
      ...>
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Blockquote.to_ast(input)
      %Markright.Continuation{ast: {:blockquote, %{},
             "Hello\n — world!"}, tail: " Other text.\n "}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  @max_indent Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: ast, tail: tail} <- astify(input, fun),
         %C{ast: block, tail: ""} <- Markright.Parsers.Generic.to_ast(ast),
      do: Markright.Utils.continuation(%C{ast: block, tail: tail}, {:blockquote, opts, fun})
  end

  ##############################################################################

  @spec astify(String.t, Function.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, acc \\ Buf.empty())

  ##############################################################################

  defp astify(<<
                unquote(@splitter) :: binary, # @splitter declared in Continuation#__using__
                rest :: binary
              >>, _fun, acc),
    do: %C{ast: acc.buffer, tail: rest}

  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)
    defp astify(<<
                  @unix_newline :: binary,
                  unquote(indent) :: binary,
                  unquote(Markright.Syntax.blocks()[:blockquote]) :: binary,
                  rest :: binary
                >>, fun, acc) do
      astify(" " <> rest, fun, acc)
    end
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
    do: astify(rest, fun, Buf.append(acc, letter))

  defp astify("", _fun, acc),
    do: %C{ast: acc.buffer, tail: ""}

  ##############################################################################
end
