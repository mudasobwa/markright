defmodule Markright.WithSyntax do
  @moduledoc ~S"""
  The implementation for the parser with syntax provided as an argument.
  """

  defmacro __using__(opts) do
    quote do
      @behaviour Markright.Parser

      @syntax unquote(opts[:syntax]) || Markright.Syntax.syntax()
      @generic_parser unquote(opts[:generic_parser]) || __MODULE__
      @max_lookahead unquote(opts[:lookahead]) || Markright.Syntax.lookahead
      @max_indent unquote(opts[:indent]) || Markright.Syntax.indent

      ##############################################################################

      require Logger
      use Markright.Continuation
      alias Markright.Continuation, as: Plume

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
            %Plume{ast: post_ast, tail: tail} = plume <- apply(@generic_parser, :to_ast, [more, plume]) do

          post_ast = if mod == @generic_parser, do: {tag, plume.attrs, post_ast}, else: post_ast
          Plume.continue(Plume.untail!(plume), Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
        end
      end

      defp astify!(:fork, tag, {plain, rest, %Plume{} = plume}) do
        with mod <- Markright.Utils.to_parser_module(tag),
             %Plume{ast: pre_ast, tail: ""} = plume <- astify(plain, plume),
             plume <- plume |> Plume.untail!,
             %Plume{ast: ast, tail: more} = plume <- apply(mod, :to_ast, [rest, plume]),
             plume <- plume |> Plume.untail!,
             %Plume{ast: post_ast, tail: tail} = plume <- apply(@generic_parser, :to_ast, [more, plume]) do

          {mine, rest} = case (if mod == @generic_parser, do: {tag, plume.attrs, ast}, else: ast) do
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
          |> Markright.Utils.surround(tag, Markright.Syntax.surrounding(tag, @syntax))
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
             %Plume{ast: post_ast, tail: tail} <- apply(@generic_parser, :to_ast, [more, plume]) do

          Plume.continue(plume, Markright.Utils.join!([pre_ast, ast, post_ast]), tail)
        end
      end

      ##############################################################################

      @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
      defp astify(part, plume)

      ##############################################################################

      Enum.each(0..@max_lookahead, fn i ->
        Module.put_attribute(__MODULE__, :i, i)
        defp astify(<<
                      plain :: binary-size(@i),
                      @splitter :: binary,
                      rest :: binary
                    >>, %Plume{} = plume) when (rest != "")  do
            astify!(:join, :block, {plain, rest, plume})
        end

        Enum.each(Markright.Syntax.magnet(@syntax), fn {tag, {delimiter, _opts}} ->
          Module.put_attribute(__MODULE__, :tag, tag)
          Module.put_attribute(__MODULE__, :delimiter, delimiter)
          defp astify(<<
                        plain :: binary-size(@i),
                        @delimiter :: binary,
                        rest :: binary
                      >>, %Plume{} = plume) do
              astify!(:magnet, @tag, {plain, @delimiter <> rest, plume})
          end
          Module.delete_attribute(__MODULE__, :delimiter)
          Module.delete_attribute(__MODULE__, :tag)
        end)

        Enum.each(Markright.Syntax.flush(@syntax), fn {tag, {delimiter, _opts}} ->
          Module.put_attribute(__MODULE__, :tag, tag)
          Module.put_attribute(__MODULE__, :delimiter, delimiter)
          defp astify(<<
                        plain :: binary-size(@i),
                        @delimiter :: binary,
                        rest :: binary
                      >>, %Plume{} = plume) do
              astify!(:flush, @tag, {plain, rest, plume})
          end
          Module.delete_attribute(__MODULE__, :delimiter)
          Module.delete_attribute(__MODULE__, :tag)
        end)

        Enum.each(Markright.Syntax.shield(@syntax), fn shield ->
          Module.put_attribute(__MODULE__, :shield, shield)
          defp astify(<<
                        plain :: binary-size(@i),
                        @shield :: binary,
                        next :: binary-size(1),
                        rest :: binary
                      >>, %Plume{} = plume) do
            astify(rest, Plume.tail!(plume, plain <> next))
          end
          Module.delete_attribute(__MODULE__, :shield)
        end)

        Enum.each(0..@max_indent, fn indent ->
          Enum.each(Markright.Syntax.lead(@syntax), fn {tag, {delimiter, _opts}} ->
            Module.put_attribute(__MODULE__, :indent, String.duplicate(" ", indent))
            Module.put_attribute(__MODULE__, :tag, tag)
            Module.put_attribute(__MODULE__, :delimiter, delimiter)
            defp astify(<<
                          plain :: binary-size(@i),
                          @unix_newline :: binary,
                          @indent :: binary,
                          @delimiter :: binary,
                          rest :: binary
                        >>, %Plume{} = plume) do
              astify!(:fork, @tag, {plain, rest, plume})
            end
            Module.delete_attribute(__MODULE__, :delimiter)
            Module.delete_attribute(__MODULE__, :tag)
            Module.delete_attribute(__MODULE__, :indent)
          end)
        end)

        Enum.each(Markright.Syntax.custom(@syntax), fn {tag, {delimiter, _opts}} ->
          Module.put_attribute(__MODULE__, :tag, tag)
          Module.put_attribute(__MODULE__, :delimiter, delimiter)
          defp astify(<<
                          plain :: binary-size(@i),
                          @delimiter :: binary,
                          rest :: binary
                      >>, %Plume{} = plume) do
              astify!(:custom, @tag, {plain, rest, plume})
          end
          Module.delete_attribute(__MODULE__, :delimiter)
          Module.delete_attribute(__MODULE__, :tag)
        end)

        Enum.each(Markright.Syntax.grip(@syntax), fn {tag, {delimiter, _opts}} ->
          Module.put_attribute(__MODULE__, :tag, tag)
          Module.put_attribute(__MODULE__, :delimiter, delimiter)
          defp astify(<<
                          plain :: binary-size(@i),
                          @delimiter :: binary,
                          rest :: binary
                      >>, %Plume{} = plume) do
            case Plume.detag!(plume) do
              {{@tag, _opts}, cont} ->
                %Plume{astify(plain, cont) | tail: rest}
              _ ->
                cont = Plume.tag!(plume, {@tag, %{}})
                astify!(:split, @tag, {plain, rest, cont})
            end
          end
          Module.delete_attribute(__MODULE__, :delimiter)
          Module.delete_attribute(__MODULE__, :tag)
        end)
        Module.delete_attribute(__MODULE__, :i)
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
  end
end
