defmodule Markright.Parsers.Generic do
  @moduledoc ~S"""
  The generic, aka topmost, aka multi-purpose parser, used when
  there is no specific parser declared for the tag.
  """

  @behaviour Markright.Parser

  ##############################################################################

  @max_lookahead Markright.Syntax.lookahead
  @max_indent    Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume) when is_binary(input),
    do: astify(input, plume)

  @spec astify!(Atom.t, Atom.t, {String.t, String.t, Markright.Continuation.t}) :: Markright.Continuation.t
  defp astify!(:split, tag, {plain, rest, %Plume{} = plume}) do
    with %Plume{ast: pre_ast, tail: ""} = plume <- astify(plain, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: {:nil, attrs, rest}} = plume <- Markright.Parsers.ClassOrId.to_ast(rest, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: ast, tail: more} = plume <- astify(rest, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: post_ast, tail: tail} = plume <- astify(more, plume) do

      Plume.continue(Plume.untail!(plume), Markright.Utils.join!([pre_ast, {tag, attrs, ast}, post_ast]), tail)
    end
  end

  defp astify!(:custom, tag, {plain, rest, %Plume{} = plume}) do
    with mod <- Markright.Utils.to_parser_module(tag),
        %Plume{ast: pre_ast, tail: ""} = plume <- astify(plain, plume),
         plume <- plume |> Plume.untail!,
        %Plume{ast: ast, tail: more} = plume <- apply(mod, :to_ast, [rest, plume]),
         plume <- plume |> Plume.untail!,
        %Plume{ast: post_ast, tail: tail} = plume <- Markright.Parsers.Generic.to_ast(more, plume) do

      post_ast = if mod == Markright.Parsers.Generic, do: {tag, plume.attrs, post_ast}, else: post_ast
      Plume.continue(Plume.untail!(plume), Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
    end
  end

  defp astify!(:fork, tag, {plain, rest, %Plume{} = plume}) do
    with mod <- Markright.Utils.to_parser_module(tag),
         %Plume{ast: pre_ast, tail: ""} = plume <- astify(plain, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: ast, tail: more} = plume <- apply(mod, :to_ast, [rest, plume]),
         plume <- plume |> Plume.untail!,
         %Plume{ast: post_ast, tail: tail} = plume <- Markright.Parsers.Generic.to_ast(more, plume) do

      {mine, rest} = case (if mod == Markright.Parsers.Generic, do: {tag, plume.attrs, ast}, else: ast) do
        {tag, opts, ast} ->
          {m, r} = Markright.Utils.split_ast(ast)
          {{tag, opts, m}, r}
        few when is_list(few) ->
          case :lists.reverse(few) do
            [{tag, opts, ast} | t] ->
              {m, r} = Markright.Utils.split_ast(ast)
              {:lists.reverse([{tag, opts, m} | t]), r}
            list when is_list(list) -> {:lists.reverse(list), []}
          end
      end

      plume
      |> Plume.untail!
      |> Plume.continue([Markright.Utils.join!([pre_ast, mine, post_ast]), rest], tail)
      |> Markright.Utils.surround(tag, Markright.Syntax.surrounding(tag))
    end
  end

  defp astify!(:join, _tag, {plain, rest, %Plume{} = plume}) do
    with %Plume{ast: pre_ast, tail: more} <- astify(plain, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: post_ast, tail: tail} <- Markright.Parsers.Block.to_ast(more <> rest, plume) do

      Plume.continue(plume, Markright.Utils.join!([pre_ast, post_ast]), tail)
    end
  end

  # :magnet, :flush
  defp astify!(type, tag, {plain, rest, %Plume{} = plume}) do
    with mod <- Markright.Utils.to_parser_module(tag, [fallback: Markright.Utils.to_parser_module(type)]),
         %Plume{ast: pre_ast, tail: ""} <- astify(plain, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: ast, tail: more} <- apply(mod, :to_ast, [rest, plume]),
         plume <- plume |> Plume.untail!,
         %Plume{ast: post_ast, tail: tail} <- Markright.Parsers.Generic.to_ast(more, plume) do

      Plume.continue(plume, Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
    end
  end

  ##############################################################################

  @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
  defp astify(part, plume)

  ##############################################################################

  Enum.each(0..@max_lookahead, fn i ->

    defp astify(<<
                  plain :: binary-size(unquote(i)),
                  @splitter :: binary,
                  rest :: binary
                >>, %Plume{} = plume) when (rest != "")  do
        astify!(:join, :block, {plain, rest, plume})
    end

    Enum.each(Markright.Syntax.magnet(), fn {tag, {delimiter, opts}} ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, %Plume{} = plume) do
          astify!(:magnet, unquote(tag), {plain, unquote(delimiter) <> rest, plume})
      end
    end)

    Enum.each(Markright.Syntax.flush(), fn {tag, {delimiter, opts}} ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, %Plume{} = plume) do
          astify!(:flush, unquote(tag), {plain, rest, plume})
      end
    end)

    Enum.each(Markright.Syntax.shield(), fn shield ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(shield) :: binary,
                    next :: binary-size(1),
                    rest :: binary
                  >>, %Plume{} = plume) do
        astify(rest, Plume.tail!(plume, plain <> next))
      end
    end)

    Enum.each(0..@max_indent, fn indent ->
      indent = String.duplicate(" ", indent)
      Enum.each(Markright.Syntax.lead(), fn {tag, {delimiter, opts}} ->
        defp astify(<<
                      plain :: binary-size(unquote(i)),
                      @unix_newline :: binary,
                      unquote(indent) :: binary,
                      unquote(delimiter) :: binary,
                      rest :: binary
                    >>, %Plume{} = plume) do
          astify!(:fork, unquote(tag), {plain, rest, plume})
        end
      end)
    end)

    Enum.each(Markright.Syntax.custom(), fn {tag, {delimiter, opts}} ->
      defp astify(<<
                      plain :: binary-size(unquote(i)),
                      unquote(delimiter) :: binary,
                      rest :: binary
                  >>, %Plume{} = plume) do
          astify!(:custom, unquote(tag), {plain, rest, plume})
      end
    end)

    Enum.each(Markright.Syntax.grip(), fn {tag, {delimiter, opts}} ->
      defp astify(<<
                      plain :: binary-size(unquote(i)),
                      unquote(delimiter) :: binary,
                      rest :: binary
                  >>, %Plume{} = plume) do
        case Plume.detag!(plume) do
          {{unquote(tag), _opts}, cont} ->
            %Plume{astify(plain, cont) | tail: rest}
          _ ->
            cont = Plume.tag!(plume, {unquote(tag), %{}})
            astify!(:split, unquote(tag), {plain, rest, cont})
        end
      end
    end)
  end)

  defp astify(<<plain :: binary-size(@max_lookahead), rest :: binary>>, %Plume{} = plume) do
    astify(rest, Plume.tail!(plume, plain))
  end

  ##############################################################################
  ### MUST BE LAST
  ##############################################################################

  defp astify(unmatched, %Plume{} = plume) when is_binary(unmatched) do
    {tail, cont} = plume
                   |> Plume.tail!(unmatched)
                   |> Plume.detail!
    %Plume{cont | ast: tail, tail: ""}
  end

end
