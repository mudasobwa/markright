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

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    C.continue(Markright.Parsers.Generic.to_ast("\n\n" <> input, fun), {:article, opts})
    |> C.callback(fun)
  end

end
