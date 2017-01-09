defmodule Markright.Parsers.Article do
  @moduledoc ~S"""
  Parses the whole text.

  ## Examples

      iex> "[http://example.com Hello my] lovely world!" |> Markright.Parsers.Article.to_ast
      {:article, %{},
        {:p, %{}, {{:img, %{src: "http://example.com", alt: "Hello my"}, nil}, " lovely world!"}}}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: ast, tail: tail} <- C.callback(C.continue(astify(input), {:article, %{}}), fun) do
      Logger.error "☆ARTICL☆ #{inspect({ast, tail})}"
      if opts[:only] == :ast, do: ast, else: %C{ast: ast, tail: tail}
    end
  end

  defp astify(input, acc \\ []) do
    case Markright.Parsers.Generic.to_ast("\n\n" <> input) do
      %C{ast: "", tail: ""} -> %C{ast: acc}
      %C{ast: ast, tail: ""} -> %C{ast: acc ++ [ast]}
      %C{ast: "", tail: tail} -> astify(tail, acc)
      %C{ast: ast, tail: tail} -> astify(tail, acc ++ [ast])
    end
  end

end
