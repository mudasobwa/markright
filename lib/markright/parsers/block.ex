defmodule Markright.Parsers.Block do
  @moduledoc ~S"""
  Parses the input for the block (delimited by empty lines.)
  """

  @behaviour Markright.Parser

  @max_lookahead Markright.Syntax.lookahead
  @max_indent    Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    astify(input, fun, opts)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(0..@max_lookahead-1, fn i ->
    defp astify(<<
                  plain :: binary-size(unquote(i)),
                  "\n\n" :: binary,
                  rest :: binary
                >>, fun, opts, acc) do
      Logger.debug "★ BLOCK★ [:p] #{inspect({plain, rest})}"
      with %C{ast: post_ast, tail: tail} <- Markright.Parsers.Generic.to_ast("\n\n" <> rest, fun, opts),
           %C{ast: pre_ast} <- astify(plain, fun, opts, acc) do
        %C{ast: [pre_ast, post_ast], tail: tail}
      end
    end
  end)

  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)

    Enum.each(Markright.Syntax.blocks(), fn {tag, delimiter} ->
      defp astify(<<
                    unquote(indent) :: binary,
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, fun, opts, _acc) when not(rest == "") do
        Logger.error "☆ BLOCK☆ [#{unquote(delimiter)}] #{rest}"
        with mod <- Markright.Utils.to_module(unquote(tag)),
            {post_ast, tail} <- apply(mod, :to_ast, [rest, fun, opts]) do
          post_ast = if mod == Markright.Parsers.Generic, do: {unquote(tag), opts, post_ast}, else: post_ast
          %C{ast: post_ast, tail: tail}
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

  defp astify(input, fun, opts, _acc) when is_binary(input) do
    with cont <- Markright.Parsers.Generic.to_ast(input, fun, opts) do
      %C{cont | ast: {:p, opts, cont.ast}}
    end
  end

  ##############################################################################
end
