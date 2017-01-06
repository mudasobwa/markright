defmodule Markright.Parsers.Li do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = " item 1
      ...> ever
      ...> "
      iex> Markright.Parsers.Li.to_ast(input)
      {{:li, %{}, "item 1"}, "\n ever\n "}
  """

  @behaviour Markright.Parser

  use Markright.Buffer

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty())
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    case astify(input, fun, opts, acc) do
      {item, ""} -> {{:li, %{}, item}, ""}
      {item, rest} -> {{:li, %{}, item}, "\n" <> rest}
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc)

  ##############################################################################

  defp astify(<<"\n" :: binary, rest :: binary>>, _fun, _opts, acc),
    do: {String.trim(acc.buffer), rest}

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  defp astify("", _fun, _opts, acc),
    do: {String.trim(acc.buffer), ""}

  ##############################################################################
end
