defmodule Markright.Parsers.Img.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Img

  @input ~S"""
  Hello, ![GitHub link](https://github.com).

  Hello, ![Atlassian link|https://atlassian.com].

  Hello, ![https://example.com normal link].
  """

  @output {:article, %{}, [
    {:p, %{}, ["Hello, ", {:img, %{src: "https://github.com", alt: "GitHub link"}, nil}, "."]},
    {:p, %{}, ["Hello, ", {:img, %{src: "https://atlassian.com", alt: "Atlassian link"}, nil}, "."]},
    {:p, %{}, ["Hello, ", {:img, %{src: "https://example.com", alt: "normal link"}, nil}, ".\n"]}]}

  test "parses different types of links" do
    assert (@input
            |> Markright.to_ast) == @output
  end
end
