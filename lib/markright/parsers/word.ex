defmodule Markright.Parsers.Word do
  @behaviour Markright.Parser

  use Markright.Buffer

  @moduledoc ~S"""
  Parses the input until the first occurence of a space.

  ## Examples

      iex> "Hello my lovely world!" |> Markright.Parsers.Word.to_ast
      {"Hello", "my lovely world!"}
  """

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty()) \
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts),
  do: astify(input, fun, opts, acc)

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc)

  ##############################################################################

  # FIXME: make this list dynamic
  Enum.each([" ", "\n", "\t", "\r"], fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, _fun, _opts, acc),
      do: {acc.buffer, rest}
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  defp astify("", _fun, _opts, acc),
    do: {acc.buffer, ""}

  ##############################################################################
end
