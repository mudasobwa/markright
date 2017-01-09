defmodule Markright.Parsers.Generic do
  @behaviour Markright.Parser

  ##############################################################################

  @max_lookahead Markright.Syntax.lookahead
  @max_indent    Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  import Markright.Utils, only: [leavify: 1, deleavify: 1]

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    astify(input, fun, opts, Buf.empty())
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(0..@max_lookahead-1, fn i ->
    Enum.each(Markright.Syntax.shields(), fn shield ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(shield) :: binary,
                    next :: binary-size(1),
                    rest :: binary
                  >>, fun, opts, acc) do
        astify(rest, fun, opts, Buf.append(acc, plain <> next))
      end
    end)

    Enum.each(0..@max_indent-1, fn indent ->
      indent = String.duplicate(" ", indent)
      Enum.each(Markright.Syntax.leads(), fn {tag, delimiter} ->
        defp astify(<<
                      plain :: binary-size(unquote(i)),
                      "\n" :: binary,
                      unquote(indent) :: binary,
                      unquote(delimiter) :: binary,
                      rest :: binary
                    >>, fun, opts, acc) do
          # FIXME: refactor here and below
          with mod <- Markright.Utils.to_module(unquote(tag)),
              %C{ast: post_ast, tail: tail} <- apply(mod, :to_ast, [rest, fun, opts]),
              %C{ast: pre_ast} <- astify(plain, fun, opts, acc) do
            post_ast = if mod == Markright.Parsers.Generic, do: {unquote(tag), opts, post_ast}, else: post_ast
            # FIXME: C.callback() if Generic
            %C{ast: [pre_ast, post_ast], tail: tail}
          end
        end
      end)
    end)

    Enum.each(Markright.Syntax.customs(), fn {tag, delimiter} ->
      defp astify(<<
                      plain :: binary-size(unquote(i)),
                      unquote(delimiter) :: binary,
                      rest :: binary
                  >>, fun, opts, acc) do
        with mod <- Markright.Utils.to_module(unquote(tag)),
            %C{ast: post_ast, tail: tail} <- apply(mod, :to_ast, [rest, fun, opts]),
            %C{ast: pre_ast} <- astify(plain, fun, opts, acc) do
          post_ast = if mod == Markright.Parsers.Generic, do: {unquote(tag), opts, post_ast}, else: post_ast
          # FIXME: C.callback() if Generic
          %C{ast: [pre_ast, post_ast], tail: tail}
        end
      end
    end)

    Enum.each(Markright.Syntax.grips(), fn {tag, delimiter} ->
      defp astify(<<
                      plain :: binary-size(unquote(i)),
                      unquote(delimiter) :: binary,
                      rest :: binary
                  >>, fun, opts, acc) do
        case Buf.shift(acc) do
          {{unquote(tag), opts}, _tail} ->
            %C{astify(plain, fun, opts, acc) | tail: rest} # TODO: Buf.cleanup(tail)
          _ ->
            with %C{ast: pre_ast} <- astify(plain, fun, opts, acc),
                 %C{ast: post_ast, tail: tail} <- astify(rest, fun, opts, Buf.unshift_and_cleanup(acc, {unquote(tag), opts})) do
              %C{ast: [pre_ast, post_ast], tail: tail}
            end
        end
      end
    end)
  end)

  defp astify(<<plain :: binary-size(@max_lookahead), rest :: binary>>, fun, opts, acc) do
    astify(rest, fun, opts, Buf.append(acc, plain))
  end

  ##############################################################################
  ### MUST BE LAST
  ##############################################################################

  defp astify(unmatched, _fun, _opts, acc) when is_binary(unmatched) do
    %C{ast: Buf.append(acc, unmatched).buffer, tail: ""}
  end

end
