defmodule Markright.Presets.Article do
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

  @behaviour Markright.Preset
  use Markright.Top

  def syntax do
    [
      lookahead: 10,
      indent: 10,
      shield: ~w|/ \\|,

      block: [
        h: "#",
        h: "§",
        pre: "```",
        blockquote: ">"
      ],
      flush: [
        hr: "\n---",
        br: "  \n",
        br: "  \n"
      ],
      lead: [
        li: {"-", [parser: Markright.Parsers.Li]},
        li: {"•", [parser: Markright.Parsers.Li]},
        dt: {"▷", [parser: Markright.Parsers.Dt]}
      ],
      magnet: [
        maillink: "mailto:",
        httplink: "http://",
        httpslink: "https://",
        lj: "✎",
        tag: "#",
        youtube: "✇"
      ],
      grip: [
        span: "⇓",
        em: "_",
        strong: "*",
        b: "**",
        strike: "~",
      ],
      custom: [
        link: "[",
        img: "![",
        code: "`",
      ],
      surrounding: [
        li: :ul,
        dt: :dl
      ]
    ]
  end
end
