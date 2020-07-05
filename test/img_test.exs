defmodule Markright.Parsers.Img.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Img

  @input ~S"""
  Hello, ![GitHub link](https://github.com).

  Hello, ![GitHub](https://github.com).

  Hello, ![Atlassian|https://atlassian.com].

  Hello, ![https://example.com normal link].
  """

  @output {:article, %{},
           [
             {:p, %{},
              [
                "Hello, ",
                {:figure, %{},
                 [
                   {:img, %{alt: "GitHub link", src: "https://github.com"}, nil},
                   {:figcaption, %{}, "GitHub link"}
                 ]},
                "."
              ]},
             {:p, %{},
              [
                "Hello, ",
                {:figure, %{},
                 [
                   {:img, %{alt: "GitHub", src: "https://github.com"}, nil},
                   {:figcaption, %{}, "GitHub"}
                 ]},
                "."
              ]},
             {:p, %{},
              [
                "Hello, ",
                {:figure, %{},
                 [
                   {:img, %{alt: "Atlassian", src: "https://atlassian.com"}, nil},
                   {:figcaption, %{}, "Atlassian"}
                 ]},
                "."
              ]},
             {:p, %{},
              [
                "Hello, ",
                {:figure, %{},
                 [
                   {:img, %{alt: "normal link", src: "https://example.com"}, nil},
                   {:figcaption, %{}, "normal link"}
                 ]},
                "."
              ]}
           ]}

  test "parses different types of links" do
    assert @input
           |> Markright.to_ast() == @output
  end
end
