defmodule Markright.Parsers.Link.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Link

  @input ~S"""
  Hello, [GitHub link](https://github.com).

  Hello, [Atlassian link|https://atlassian.com].

  Hello, [https://example.com normal link].
  """

  @output [
    {:p, %{}, ["Hello, ", {:a, %{href: "https://github.com"}, "GitHub link"}, "."]},
    {:p, %{}, ["Hello, ", {:a, %{href: "https://atlassian.com"}, "Atlassian link"}, "."]},
    {:p, %{}, ["Hello, ", {:a, %{href: "https://example.com"}, "normal link"}, "."]}]

  test "parses different types of links" do
    assert (@input
            |> Markright.to_ast
            |> IO.inspect) == @output
  end
end
