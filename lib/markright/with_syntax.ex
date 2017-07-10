defmodule Markright.WithSyntax do
  @moduledoc ~S"""
  The implementation for the parser with syntax provided as an argument.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Markright.Parser

      syntax = opts[:syntax] || Markright.Syntax.syntax()
      Module.put_attribute(__MODULE__, :syntax, syntax)
      @generic_parser opts[:generic_parser] || __MODULE__
      @max_lookahead opts[:lookahead] || Markright.Syntax.lookahead
      @max_indent opts[:indent] || Markright.Syntax.indent

      ##############################################################################

      block_module_content =
        quote do
          @behaviour Markright.Parser
          @max_indent Markright.Syntax.indent
          Module.put_attribute(__MODULE__, :syntax, unquote(syntax) || Markright.Syntax.syntax())
          use Markright.Continuation
          alias Markright.Continuation, as: Plume

          def to_ast(input, %Plume{} = plume) when is_binary(input),
            do: astify(String.trim_leading(input), plume)

          @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
          defp astify(input, plume)

          defp astify(<<@splitter :: binary, rest :: binary>>, %Plume{} = plume),
            do: Plume.tail!(plume, rest)

          Enum.each(0..@max_indent, fn indent ->
            Enum.each(Markright.Syntax.block(@syntax), fn {tag, {delimiter, _opts}} ->
              Module.put_attribute(__MODULE__, :indent, String.duplicate(" ", indent))
              Module.put_attribute(__MODULE__, :tag, tag)
              Module.put_attribute(__MODULE__, :delimiter, delimiter)
              defp astify(<<
                            @indent :: binary,
                            @delimiter :: binary,
                            rest :: binary
                          >>, %Plume{} = plume) when not(rest == "") do

                with mod <- Markright.Utils.to_parser_module(@tag), # TODO: extract this with into Utils fun
                     %Plume{} = ast <- apply(mod, :to_ast, [rest, plume]),
                     %Plume{} = ast <- Markright.Utils.delimit(ast) do

                  if mod == plume.bag[:parser], # FIXME
                    do: Markright.Utils.continuation(ast, {@tag, %{}}),
                    else: ast
                end
              end
              Module.delete_attribute(__MODULE__, :delimiter)
              Module.delete_attribute(__MODULE__, :tag)
              Module.delete_attribute(__MODULE__, :indent)
            end)
            defp astify("", plume), do: plume
            defp astify(rest, %Plume{} = plume) when is_binary(rest) do
              with %Plume{} = cont <- apply(plume.bag[:parser], :to_ast, [@unix_newline <> rest, plume]) do
                {mine, rest} = Markright.Utils.split_ast(cont.ast)

                %Plume{cont |
                  ast: [Markright.Utils.continuation(:ast, %Plume{cont | ast: trim_leading(mine)}, {:p, %{}}), rest],
                  tail: Markright.Utils.delimit(cont).tail}
              end
            end
          end)

          defp trim_leading(input) when is_binary(input), do: String.trim_leading(input)
          defp trim_leading([h | t]) when is_binary(h), do: [trim_leading(h) | t]
          defp trim_leading(other), do: other
        end
      Module.put_attribute(__MODULE__, :block_module, Module.concat(__MODULE__, "Block"))
      Module.create(@block_module, block_module_content, Macro.Env.location(__ENV__))

      ##############################################################################

      require Logger
      use Markright.Continuation
      alias Markright.Continuation, as: Plume

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
             %Plume{ast: post_ast, tail: tail} <- apply(@block_module, :to_ast, [more <> rest, plume]) do

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
