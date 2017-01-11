defmodule Markright.Parsers.Word do
  @moduledoc ~S"""
  Parses the input until the first occurence of a space.

  ## Examples

      iex> "Hello my lovely world!" |> Markright.Parsers.Word.to_ast
      %Markright.Continuation{ast: "Hello", tail: "my lovely world!"}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{}) \
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts),
  do: astify(input, fun)

  ##############################################################################

  @spec astify(String.t, Function.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, acc \\ Buf.empty())

  ##############################################################################

  # FIXME: make this list dynamic
  Enum.each([" ", @unix_newline, "\t", "\r"], fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, _fun, acc),
      do: %C{ast: acc.buffer, tail: rest}
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
    do: astify(rest, fun, Buf.append(acc, letter))

  defp astify("", _fun, acc),
    do: %C{ast: acc.buffer}

  ##############################################################################
end
