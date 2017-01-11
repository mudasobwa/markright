defmodule Markright.Parsers.Li do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = " item 1
      ...> ever
      ...> - item 2
      ...> "
      iex> Markright.Parsers.Li.to_ast(input)
      %Markright.Continuation{ast: {:li, %{}, "item 1\n ever"}, tail: "\n - item 2\n "}

      iex> input = " item 1
      ...> *ever*
      ...> - item 2
      ...> "
      iex> Markright.Parsers.Li.to_ast(input)
      %Markright.Continuation{ast: {:li, %{}, ["item 1\n ", {:strong, %{}, "ever"}]}, tail: "\n - item 2\n "}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  @max_indent Markright.Syntax.indent

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: ast, tail: tail} <- astify(input, fun, opts),
         %C{ast: block, tail: ""} <- Markright.Parsers.Generic.to_ast(ast) do

      Markright.Utils.continuation(%C{ast: block, tail: tail}, {:li, opts, fun})
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  li = Markright.Syntax.leads()[:li]
  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)
    defp astify(<<
                  @unix_newline :: binary,
                  unquote(indent) :: binary,
                  unquote(li) :: binary,
                  rest :: binary
                >>, _fun, _opts, acc) do
      %C{ast: String.trim(acc.buffer), tail: @unix_newline <> unquote(indent) <> unquote(li) <> rest}
    end
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  defp astify("", _fun, _opts, acc),
    do: %C{ast: String.trim(acc.buffer), tail: ""}

  ##############################################################################
end
