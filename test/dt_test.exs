defmodule Markright.Parsers.Dt.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Dt

  @input """
  Hello, world! Data terms here:
  ▷ item 1: definition 1
  ▷ item 2: definition 2
  ▷ item 3: definition 3

  Afterparty.
  """

  @output {
    :article, %{},
      [{:p, %{}, [
          "Hello, world! Data terms here:",
          {:dl, %{}, [
            {:dt, %{}, "item 1"}, {:dd, %{}, " definition 1"},
            {:dt, %{}, "item 2"}, {:dd, %{}, " definition 2"},
            {:dt, %{}, "item 3"}, {:dd, %{}, " definition 3"}]}]},
       {:p, %{}, "Afterparty."}]}

  test "parses [different types of] data terms" do
    assert (@input
            |> Markright.to_ast) == @output
  end
end
