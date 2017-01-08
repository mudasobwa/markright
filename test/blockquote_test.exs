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
    with %Markright.Continuation{ast: ast, tail: tail} <- Markright.to_ast(@input) do
      assert Enum.count(ast) == 3
      assert Enum.at(ast, 0) == {:p, %{}, ["Hello, ", {:strong, %{}, "world"}, "!"]}
      assert Enum.at(ast, 1) == {:blockquote, %{}, [
                                  " This is a ",
                                  {:em, %{}, "blockquote"},
                                  ".\n       It is multiline."
                                ]}
      assert Enum.at(ast, 2) == {:p, %{}, ["Cordially, ", {:em, %{}, "Markright"}, "."] }
      assert tail == ""
    end
  end
end
