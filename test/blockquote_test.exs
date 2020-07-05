defmodule Markright.Parsers.Blockquote.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Blockquote

  @input ~S"""
  Hello, *world*!

  > This is a _blockquote_.
    It is multiline.

  Cordially, _Markright_.
  """

  test "it handles blockquotes" do
    with {:article, _, ast} <- Markright.to_ast(@input) do
      assert Enum.count(ast) == 3
      assert Enum.at(ast, 0) == {:p, %{}, ["Hello, ", {:strong, %{}, "world"}, "!"]}

      assert Enum.at(ast, 1) ==
               {:blockquote, %{},
                [
                  " This is a ",
                  {:em, %{}, "blockquote"},
                  ".\n  It is multiline."
                ]}

      assert Enum.at(ast, 2) == {:p, %{}, ["Cordially, ", {:em, %{}, "Markright"}, ".\n"]}
    end
  end

  @input ~S"""
  Hello, *world*!

  > This is a _blockquote_.
    It is multiline.
    [http://example.com Reference link]

  Cordially, _Markright_.
  """

  test "it handles references in blockquotes" do
    with {:article, _, ast} <- Markright.to_ast(@input) do
      assert Enum.count(ast) == 3
      assert Enum.at(ast, 0) == {:p, %{}, ["Hello, ", {:strong, %{}, "world"}, "!"]}

      assert Enum.at(ast, 1) ==
               {:blockquote, %{cite: "http://example.com"},
                [
                  " This is a ",
                  {:em, %{}, "blockquote"},
                  ".\n  It is multiline.\n  ",
                  {:br, %{}, nil},
                  "— ",
                  {:img,
                   %{
                     alt: "favicon",
                     src: "http://example.com/favicon.png",
                     style: "height:16px;margin-bottom:-2px;"
                   }, nil},
                  " ",
                  {:a, %{href: "http://example.com"}, "Reference link"}
                ]}

      assert Enum.at(ast, 2) == {:p, %{}, ["Cordially, ", {:em, %{}, "Markright"}, ".\n"]}
    end
  end
end
