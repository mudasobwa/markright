defmodule Markright.Parsers.Link.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Link

  @input ~S"""
  111, [GitHub link](https://github.com).

  222, [Atlassian **bold** link|https://atlassian.com].

  333, [https://example.com normal link].
  """

  @output {:article, %{},
           [
             {:p, %{}, ["111, ", {:a, %{href: "https://github.com"}, "GitHub link"}, "."]},
             {:p, %{},
              [
                "222, ",
                {:a, %{href: "https://atlassian.com"},
                 ["Atlassian ", {:b, %{}, "bold"}, " link"]},
                "."
              ]},
             {:p, %{}, ["333, ", {:a, %{href: "https://example.com"}, "normal link"}, "."]}
           ]}

  @output_xml ~s"""
  <article>
  \t<p>
  \t\t111,\s
  \t\t<a href=\"https://github.com\">GitHub link</a>
  \t\t.
  \t</p>
  \t<p>
  \t\t222,\s
  \t\t<a href=\"https://atlassian.com\">
  \t\t\tAtlassian\s
  \t\t\t<b>bold</b>
  \t\t\t link
  \t\t</a>
  \t\t.
  \t</p>
  \t<p>
  \t\t333,\s
  \t\t<a href=\"https://example.com\">normal link</a>
  \t\t.
  \t</p>
  </article>
  """

  test "parses different types of links" do
    assert @input
           |> Markright.to_ast() == @output
  end

  test "produces proper XML for different types of links" do
    assert @input
           |> Markright.to_ast()
           |> XmlBuilder.generate(format: :none) ==
             String.replace(@output_xml, ~r/\n|\t/, "")
  end
end
