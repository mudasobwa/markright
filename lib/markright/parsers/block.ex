defmodule Markright.Parsers.Block do
  @moduledoc ~S"""
  Parses the input for the block (delimited by empty lines.)
  """

  @behaviour Markright.Parser

  @max_indent Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume) when is_binary(input),
    do: astify(String.trim_leading(input), plume)

  ##############################################################################

  @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
  defp astify(input, plume)

  ##############################################################################

  defp astify(<<unquote(@splitter) :: binary, rest :: binary>>, %Plume{} = plume),
    do: Plume.tail!(plume, rest)

  Enum.each(0..@max_indent, fn i ->
    indent = String.duplicate(" ", i)
    Enum.each(Markright.Syntax.block(), fn {tag, {delimiter, _opts}} ->
      defp astify(<<
                    unquote(indent) :: binary,
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, %Plume{} = plume) when not(rest == "") do

        with mod <- Markright.Utils.to_parser_module(unquote(tag)), # TODO: extract this with into Utils fun
             %Plume{} = ast <- apply(mod, :to_ast, [rest, plume]),
             %Plume{} = ast <- Markright.Utils.delimit(ast) do

          if mod == plume.bag[:parser], # FIXME
            do: Markright.Utils.continuation(ast, {unquote(tag), %{}}),
            else: ast
        end
      end
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
