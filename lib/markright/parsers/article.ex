defmodule Markright.Parsers.Article do
  @moduledoc ~S"""
  Parses the whole text, producing a single article item.

  ## Examples

      iex> cont = "![http://example.com Hello my] lovely world!" |> Markright.Parsers.Article.to_ast
      ...> cont.ast
      {:article, %{},
        [{:p, %{}, [
              {:figure, %{},
                [{:img, %{alt: "Hello my", src: "http://example.com"}, nil},
                 {:figcaption, %{}, "Hello my"}]}, " lovely world!"]}]}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation, as: Plume

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}, syntax \\ nil) when is_binary(input) do
    Markright.Utils.continuation(astify(input, plume, syntax), {:article, %{}})
  end

  ##############################################################################

  defp astify(input, %Plume{} = plume, syntax) do
    parser_module = parser(syntax) || plume.bag[:parser]
    plume = %Plume{plume | bag: [parser: parser_module, syntax: syntax]}

    case apply(parser_module, :to_ast, [@splitter <> input, plume]) do
      %Plume{ast: "", tail: ""} -> plume
      %Plume{ast: ast, tail: ""} -> %Plume{plume | ast: plume.ast ++ [ast]}
      %Plume{ast: "", tail: tail} -> astify(tail, plume, syntax) # %Plume{plume | ast: tail, tail: ""}
      %Plume{ast: ast, tail: tail} -> astify(tail, %Plume{plume | ast: plume.ast ++ [ast]}, syntax)
    end
  end

  defp parser(nil), do: nil
  defp parser(syntax) do
    hash = :md5
           |> :crypto.hash(inspect(syntax))
           |> Base.encode16
    Markright.Utils.parser!(Module.concat("Markright.Parsers", "Syntax_#{hash}"), syntax, __ENV__)
  end
end
