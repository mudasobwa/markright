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
  defp astify!(:split, tag, {plain, rest, fun, opts, acc}) do
    with %C{ast: pre_ast, tail: ""} <- astify(plain, fun, opts, acc),
         %C{ast: {:nil, attrs, rest}} <- Markright.Parsers.ClassOrId.to_ast(rest, fun, opts),
         %C{ast: ast, tail: more} <- astify(rest, fun, opts, Buf.unshift_and_cleanup(acc, {tag, opts})),
         %C{ast: post_ast, tail: tail} <- astify(more, fun, opts, Buf.cleanup(acc)) do

      C.continue(Markright.Utils.join!([pre_ast, {tag, attrs, ast}, post_ast]), tail)
    end
  end

  defp astify!(:inplace, tag, {plain, rest, fun, opts, acc}) do
    with mod <- Markright.Utils.to_module(tag),
        %C{ast: pre_ast, tail: ""} <- astify(plain, fun, opts, acc),
        %C{ast: ast, tail: more} <- apply(mod, :to_ast, [rest, fun, opts]),
        %C{ast: post_ast, tail: tail} <- Markright.Parsers.Generic.to_ast(more, fun, opts) do

      post_ast = if mod == Markright.Parsers.Generic, do: {tag, opts, post_ast}, else: post_ast
      C.continue(Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
    end
  end

  defp astify!(:magnet, tag, {plain, rest, fun, opts, acc}) do
    with mod <- Markright.Utils.to_module(tag, [fallback: Markright.Parsers.Magnet]),
        %C{ast: pre_ast, tail: ""} <- astify(plain, fun, opts, acc),
        %C{ast: ast, tail: more} <- apply(mod, :to_ast, [rest, fun, opts]),
        %C{ast: post_ast, tail: tail} <- Markright.Parsers.Generic.to_ast(more, fun, opts) do

      C.continue(Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
    end
  end

  defp astify!(:fork, tag, {plain, rest, fun, opts, acc}) do
    with mod <- Markright.Utils.to_module(tag),
        %C{ast: pre_ast, tail: ""} <- astify(plain, fun, opts, acc),
        %C{ast: ast, tail: more} <- apply(mod, :to_ast, [rest, fun, opts]),
        %C{ast: post_ast, tail: tail} <- Markright.Parsers.Generic.to_ast(more, fun, opts) do

      {tag, opts, ast} = if mod == Markright.Parsers.Generic, do: {tag, opts, ast}, else: ast
      {mine, rest} = Markright.Utils.split_ast(ast)

      [Markright.Utils.join!([pre_ast, {tag, opts, mine}, post_ast]), rest]
      |> C.continue(tail)
      |> Markright.Utils.surround(tag, Markright.Syntax.surrounding(tag))
    end
  end

  defp astify!(:join, _tag, {plain, rest, fun, opts, acc}) do
    with %C{ast: pre_ast, tail: more} <- astify(plain, fun, opts, acc),
         %C{ast: post_ast, tail: tail} <- Markright.Parsers.Block.to_ast(more <> rest, fun, opts) do

      C.continue(Markright.Utils.join!([pre_ast, post_ast]), tail)
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(0..@max_lookahead, fn i ->
    defp astify(<<
                  plain :: binary-size(unquote(i)),
                  @splitter :: binary,
                  rest :: binary
                >>, fun, opts, acc) when (rest != "")  do
        astify!(:join, :block, {plain, rest, fun, opts, acc})
    end

    Enum.each(Markright.Syntax.shield(), fn shield ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(shield) :: binary,
                    next :: binary-size(1),
                    rest :: binary
                  >>, fun, opts, acc) do
        astify(rest, fun, opts, Buf.append(acc, plain <> next))
      end
    end)

    Enum.each(Markright.Syntax.magnet(), fn {tag, delimiter} ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, fun, opts, acc) do
          astify!(:magnet, unquote(tag), {plain, rest, fun, opts, acc})
      end
    end)

    Enum.each(0..@max_indent, fn indent ->
      indent = String.duplicate(" ", indent)
      Enum.each(Markright.Syntax.lead(), fn {tag, delimiter} ->
        defp astify(<<
                      plain :: binary-size(unquote(i)),
                      @unix_newline :: binary,
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
          astify!(:inplace, unquote(tag), {plain, rest, fun, opts, acc})
      end
    end)

    Enum.each(Markright.Syntax.grip(), fn {tag, delimiter} ->
      defp astify(<<
                      plain :: binary-size(unquote(i)),
                      unquote(delimiter) :: binary,
                      rest :: binary
                  >>, fun, opts, acc) do
        case Buf.shift(acc) do
          {{unquote(tag), opts}, tail} ->
            %C{astify(plain, fun, opts, tail) | tail: rest} # TODO: Buf.cleanup(tail)
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
