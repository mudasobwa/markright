  defmodule Markright.Parsers.Maillink do
    @moduledoc ~S"""
    Makes all the mailto:who@where.domain texts to be links.

    ## Examples

        iex> input = "mailto:am@mudasobwa.ru "
        iex> Markright.Parsers.Maillink.to_ast(input, %Markright.Continuation{})
        %Markright.Continuation{ast: {:a, %{href: "mailto:am@mudasobwa.ru"}, "mailto:am@mudasobwa.ru"}, tail: " "}

        iex> input = "Hello mailto:am@mudasobwa.ru !"
        iex> Markright.to_ast(input)
        {:article, %{},
            [{:p, %{},
              ["Hello ", {:a, %{href: "mailto:am@mudasobwa.ru"}, "mailto:am@mudasobwa.ru"},
               " !"]}]}
    """

    use Markright.Helpers.Magnet
  end
