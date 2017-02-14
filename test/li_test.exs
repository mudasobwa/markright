defmodule Markright.Parsers.Li.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Li

  @input """
  Hello, world! List here:
  - item 1
  - item 2
  - item 3

  Afterparty.
  """

  @output {
    :article, %{},
      [{:p, %{}, [
          "Hello, world! List here:",
          {:ul, %{}, [{:li, %{}, "item 1"}, {:li, %{}, "item 2"}, {:li, %{}, "item 3"}]}]},
       {:p, %{}, "Afterparty."}]}

  test "parses [different types of] line items" do
    assert (@input
            |> Markright.to_ast) == @output
  end
end
