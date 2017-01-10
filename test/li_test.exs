defmodule Markright.Parsers.Li.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Li

  @input ~S"""
  Hello, world! List here:
  - item 1
  - item 2
  - item 3
  """

  @output {
    :article, %{},
      {:p, %{}, ["Hello, world! List here:", {:li, %{}, "item 1"}, {:li, %{}, "item 2"}, {:li, %{}, "item 3"}]}}

  test "parses [different types of] line items" do
    assert (@input
            |> Markright.to_ast) == @output
  end
end
