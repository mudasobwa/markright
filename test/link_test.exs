defmodule Markright.Parsers.Link.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Link

  @input ~S"""
  111, [GitHub link](https://github.com).

  222, [Atlassian **bold** link|https://atlassian.com].

  333, [https://example.com normal link].
  """

  @output {:article, %{}, [
    {:p, %{}, ["111, ", {:a, %{href: "https://github.com"}, "GitHub link"}, "."]},
    {:p, %{}, ["222, ", {:a, %{href: "https://atlassian.com"}, ["Atlassian ", {:b, %{}, "bold"}, " link"]}, "."]},
    {:p, %{}, ["333, ", {:a, %{href: "https://example.com"}, "normal link"}, "."]}]}

  @output_xml ~s"""
  <p>
  \t111,\s
  \t<a href=\"https://github.com\">GitHub link</a>
  \t.
  </p>
  <p>
  \t222,\s
  \t<a href=\"https://atlassian.com\">
  \t\tAtlassian\s
  \t\t<b>bold</b>
  \t\t link
  \t</a>
  \t.
  </p>
  <p>
  \t333,\s
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
