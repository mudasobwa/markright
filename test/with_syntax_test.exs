defmodule Markright.WithSyntax.Test do
  use ExUnit.Case
  use Markright.Continuation

  test "Custom parse" do
    input = ~S"""
    ( ) item 1
    ( ) item 2
    """
    output = Markright.to_ast(input, nil, syntax: [
      lead: [choice: {"( )", [parser: CustomParse]}],
    ])
    assert output == {:article, %{}, [{:p, %{}, [{nil, %{}, [{:choice, %{}, "item 1"}, {:choice, %{}, "item 2"}]}]}]}
  end
end

defmodule CustomParse do
  use Markright.Helpers.Lead, tag: :choice, lead_and_handler: {"( )", [CustomParse]}
end
