defmodule Markright.Parsers.Article do
  @moduledoc ~S"""
  Parses the whole text.

  ## Examples

      iex> "[http://example.com Hello my] lovely world!" |> Markright.Parsers.Article.to_ast
      {:p, %{}, {{:img, %{src: "http://example.com", alt: "Hello my"}, nil}, " lovely world!"}}
  """

  @behaviour Markright.Parser

  use Markright.Buffer

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty())
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    {:article, %{}, Markright.Parsers.Generic.to_ast("\n\n" <> input, fun, %{only: :ast}, acc)}
  end

  ##############################################################################
end
