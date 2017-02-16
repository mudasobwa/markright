defmodule Markright.Parsers.Tag.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Tag

  @input "Hi, #mudasobwa is a tag."

  @output {:article, %{},
            [{:p, %{},
              ["Hi, ",
                {:a, %{class: "tag", href: "/tags/mudasobwa"}, "mudasobwa"},
                " is a tag."]}]}

  test "parses a tag" do
    assert (@input
            |> Markright.to_ast) == @output
  end

end
