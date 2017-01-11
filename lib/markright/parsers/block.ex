defmodule Markright.Parsers.Block do
  @moduledoc ~S"""
  Parses the input for the block (delimited by empty lines.)
  """

  @behaviour Markright.Parser

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

  Enum.each(0..@max_indent, fn i ->
    indent = String.duplicate(" ", i)
    Enum.each(Markright.Syntax.blocks(), fn {tag, delimiter} ->
      defp astify(<<
                    unquote(indent) :: binary,
                    unquote(delimiter) :: binary,
                    rest :: binary
                  >>, fun, opts, _acc) when not(rest == "") do
        with mod <- Markright.Utils.to_module(unquote(tag)), # TODO: extract this with into Utils fun
             %C{} = ast <- apply(mod, :to_ast, [rest, fun, opts]) do
          if mod == Markright.Parsers.Generic,
            do: Markright.Utils.continuation(ast, {unquote(tag), opts, ast}),
            else: ast
        end
      end
    end)
    defp astify("", _fun, _opts, _acc), do: %C{}
    defp astify(rest, fun, opts, _acc) when is_binary(rest) do
      with cont <- Markright.Parsers.Generic.to_ast(rest, fun, opts) do
        {mine, rest} = case cont.ast do
                         list when is_list(list) -> Enum.split_while(cont.ast, fn
                                                      {:p, _, _} -> false
                                                      {:pre, _, _} -> false
                                                      {:blockquote, _, _} -> false
                                                      _ -> true
                                                    end)
                         string when is_binary(string) -> {string, []}
                       end

        %C{ast: [Markright.Utils.continuation(:ast, %C{ast: mine}, {:p, opts, fun}), rest],
           tail: (if Markright.Guards.empty?(cont.tail), do: "", else: @splitter <> cont.tail)}
      end
    end
  end)
end
