defmodule Markright.Parsers.Li.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Li

  test "parses [different types of] line items without head" do
    input = """
    - item 1
    - item 2
    - item 3

    Afterparty.
    """

    output = {
      :article,
      %{},
      [
        {:p, %{},
         [
           {:ul, %{}, [{:li, %{}, "item 1"}, {:li, %{}, "item 2"}, {:li, %{}, " item 3"}]},
           "Afterparty.\n"
         ]}
      ]
    }

    assert input
           |> Markright.to_ast() == output
  end

  test "parses [different types of] line items with head" do
    input = """
      - 1

      not an item
      - A
      - B
      - C
    """

    output = {
      :article,
      %{},
      [
        {:p, %{},
         [
           {:ul, %{}, [{:li, %{}, " 1"}]},
           "  not an item",
           {:ul, %{}, [{:li, %{}, "A"}, {:li, %{}, "B"}, {:li, %{}, "C"}]}
         ]}
      ]
    }

    assert input
           |> Markright.to_ast() == output
  end

  test "parses [different types of] line items" do
    input = """
    • item 1
    • item 2
    """

    output = {
      :article,
      %{},
      [
        {:p, %{},
         [
           {:ul, %{}, [{:li, %{}, "item 1"}, {:li, %{}, "item 2"}]}
         ]}
      ]
    }

    assert input
           |> Markright.to_ast() == output
  end
end
