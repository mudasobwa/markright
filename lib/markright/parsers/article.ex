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

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    Markright.Utils.continuation(astify(input, plume), {:article, %{}})
  end

  ##############################################################################

  defp astify(input, %Plume{} = plume) do
    case Markright.Parsers.Generic.to_ast(@splitter <> input, plume) do
      %Plume{ast: "", tail: ""} -> plume
      %Plume{ast: ast, tail: ""} -> %Plume{plume | ast: plume.ast ++ [ast]}
      %Plume{ast: "", tail: tail} -> astify(tail, plume)
      %Plume{ast: ast, tail: tail} -> astify(tail, %Plume{plume | ast: plume.ast ++ [ast]})
    end
  end

end
