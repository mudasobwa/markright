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

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    astify(input, fun, opts)
  end

  @spec astify!(Atom.t, Atom.t, {String.t, String.t, Function.t, List.t, Markright.Buffer.t}) :: Markright.Continuation.t
  def astify!(:split, tag, {plain, rest, fun, opts, acc}) do
    with %C{ast: pre_ast, tail: ""} <- astify(plain, fun, opts, acc),
         %C{ast: ast, tail: more} <- astify(rest, fun, opts, Buf.unshift_and_cleanup(acc, {tag, opts})),
         %C{ast: post_ast, tail: tail} <- astify(more, fun, opts, Buf.empty()) do

      C.continue(Markright.Utils.join!([pre_ast, {tag, %{}, ast}, post_ast]), tail)
    end
  end

  def astify!(:fork, tag, {plain, rest, fun, opts, acc}) do
    with mod <- Markright.Utils.to_module(tag),
        %C{ast: pre_ast, tail: ""} <- astify(plain, fun, opts, acc),
        %C{ast: ast, tail: more} <- apply(mod, :to_ast, [rest, fun, opts]),
        %C{ast: post_ast, tail: tail} <- Markright.Parsers.Generic.to_ast(more, fun, opts) do

      post_ast = if mod == Markright.Parsers.Generic, do: {tag, opts, post_ast}, else: post_ast
      C.continue(Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(0..@max_lookahead, fn i ->
    defp astify(<<
                  plain :: binary-size(unquote(i)),
                  "\n\n" :: binary,
                  rest :: binary
                >>, fun, opts, acc) when (rest != "")  do
      astify!(:fork, :block, {plain, rest, fun, opts, acc})
    end

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

    Enum.each(0..@max_indent, fn indent ->
      indent = String.duplicate(" ", indent)
      Enum.each(Markright.Syntax.leads(), fn {tag, delimiter} ->
        defp astify(<<
                      plain :: binary-size(unquote(i)),
                      "\n" :: binary,
                      unquote(indent) :: binary,
                      unquote(delimiter) :: binary,
                      rest :: binary
                    >>, fun, opts, acc) do
          astify!(:fork, unquote(tag), {plain, rest, fun, opts, acc})
        end
      end)
    end)

    Enum.each(Markright.Syntax.customs(), fn {tag, delimiter} ->
      defp astify(<<
                      plain :: binary-size(unquote(i)),
                      unquote(delimiter) :: binary,
                      rest :: binary
                  >>, fun, opts, acc) do
          astify!(:split, unquote(tag), {plain, rest, fun, opts, acc})
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
            astify!(:split, unquote(tag), {plain, rest, fun, opts, acc})
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
