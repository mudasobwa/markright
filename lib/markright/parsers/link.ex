defmodule Markright.Parsers.Link do
  @behaviour Markright.Parser

  use Markright.Buffer

  def to_ast(input, fun, opts \\ %{}, acc \\ Buf.empty()) when is_binary(input) and
                                                              (is_nil(fun) or is_function(fun)) and
                                                               is_map(opts) do

    astify(input, fun, opts, acc)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc \\ %Buf{})

  ##############################################################################

  defp astify(<<"\n```" :: binary, rest :: binary>>, fun, opts, acc),
    do: {acc.buffer, rest}

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  ##############################################################################
end
