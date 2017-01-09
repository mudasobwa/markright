defmodule Markright.Parsers.Link.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Link

  @input ~S"""
  Hello, [GitHub link](https://github.com).

  Hello, [Atlassian **bold** link|https://atlassian.com].

  Hello, [https://example.com normal link].
  """

  @output {:article, %{}, [
    {:p, %{}, ["Hello, ", {:a, %{href: "https://github.com"}, "GitHub link"}, "."]},
    {:p, %{}, ["Hello, ", {:a, %{href: "https://atlassian.com"}, ["Atlassian ", {:b, %{}, "bold"}, " link"]}, "."]},
    {:p, %{}, ["Hello, ", {:a, %{href: "https://example.com"}, "normal link"}, "."]}]}

  @output_xml ~s"""
  <p>
  \tHello,\s
  \t<a href=\"https://github.com\">GitHub link</a>
  \t.
  </p>
  <p>
  \tHello,\s
  \t<a href=\"https://atlassian.com\">
  \t\tAtlassian\s
  \t\t<b>bold</b>
  \t\t link
  \t</a>
  \t.
  </p>
  <p>
  \tHello,\s
  \t<a href=\"https://example.com\">normal link</a>
  \t.
  </p>
  """

  test "parses different types of links" do
    assert (@input
            |> Markright.to_ast) == @output
  end

  test "produces proper XML for different types of links" do
    assert (@input
            |> Markright.to_ast
            |> XmlBuilder.generate) == String.trim(@output_xml)
  end
end
