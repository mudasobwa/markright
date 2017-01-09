defmodule Markright.Parsers.Li do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = " item 1
      ...> ever
      ...> "
      iex> Markright.Parsers.Li.to_ast(input)
      %Markright.Continuation{ast: {:li, %{}, "item 1"}, tail: "\n ever\n "}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: ast, tail: tail} <- astify(input, fun, opts) do
      case tail do
        "" -> %C{ast: {:li, %{}, ast}, tail: ""}
        rest -> %C{ast: {:li, %{}, ast}, tail: "\n" <> rest}
      end
    end
    |> C.callback(fun)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  # FIXME: Make it to accept multilines and markup itself
  defp astify(<<"\n" :: binary, rest :: binary>>, _fun, _opts, acc),
    do: %C{ast: String.trim(acc.buffer), tail: rest}

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  defp astify("", _fun, _opts, acc),
    do: %C{ast: String.trim(acc.buffer), tail: ""}

  ##############################################################################
end
