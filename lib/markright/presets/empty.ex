defmodule Markright.Presets.Empty do
  @moduledoc ~S"""
  Parses the whole text, producing a single article item.

  ## Examples

      iex> cont = "![http://example.com Hello my] lovely world!" |> Markright.Presets.Article.to_ast
      ...> cont.ast
      {:article, %{},
        [{:p, %{}, [
              {:figure, %{},
                [{:img, %{alt: "Hello my", src: "http://example.com"}, nil},
                 {:figcaption, %{}, "Hello my"}]}, " lovely world!"]}]}

      iex> "![http://example.com Hello my] lovely world!" |> Markright.article!
      {:article, %{},
        [{:p, %{}, [
              {:figure, %{},
                [{:img, %{alt: "Hello my", src: "http://example.com"}, nil},
                 {:figcaption, %{}, "Hello my"}]}, " lovely world!"]}]}
  """

  use Markright.Top, tag: :content
end
