defmodule Markright.Parsers.Block do
  @moduledoc ~S"""
  Parses the input for the block (delimited by empty lines.)
  """

  @behaviour Markright.Parser

  @max_lookahead Markright.Syntax.lookahead
  @max_indent    Markright.Syntax.indent

  use Markright.Buffer
  require Logger

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty())
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts),
    do: astify(input, fun, opts, acc)

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc)

  ##############################################################################

  Enum.each(0..@max_lookahead-1, fn i ->
    defp astify(<<
                  plain :: binary-size(unquote(i)),
                  "\n\n" :: binary,
                  rest :: binary
                >>, fun, opts, acc) do
      Logger.error "★5.5: #{inspect({plain, rest})}"
      {astify(plain, fun, opts, acc), Markright.Parsers.Generic.to_ast("\n\n" <> rest, fun, opts, Buf.empty())}
    end
  end)

  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)

    Enum.each(Markright.Syntax.blocks(), fn {tag, delimiter} ->
      defp astify(<<
                    unquote(indent) :: binary,
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, fun, opts, acc) when not(rest == "") do
        Logger.debug "★1: #{inspect(rest)}"
        with mod <- Markright.Utils.to_module(unquote(tag)),
            {code_ast, tail} <- apply(mod, :to_ast, [rest, fun, opts, Buf.unshift(acc, {unquote(tag), opts})]) do
          Logger.debug "★2: #{inspect({code_ast, tail})}"
          ast = if mod == Markright.Parsers.Generic, do: {unquote(tag), opts, code_ast}, else: code_ast
          {ast, tail}
        end
      end
      ##############################################################################
      ##  FIXME: BLOCKS CLEANUP | more elegant way?
      defp astify(<<
                    unquote(indent) :: binary,
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, fun, opts, acc), do: astify(rest, fun, opts, acc)
    end)
  end)

  defp astify(input, fun, opts, acc) when is_binary(input) do
    {ast, rest} = Markright.Parsers.Generic.to_ast(input, fun, opts, Buf.unshift(acc, {:p, %{}}))
    Logger.debug "★9: #{inspect({ast, rest})}"
    {{:p, opts, ast}, rest}
  end

  ##############################################################################
end
