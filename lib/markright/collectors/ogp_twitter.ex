defmodule Markright.Collectors.OgpTwitter do
  @moduledoc ~S"""
  Collector that basically builds the Open Graph Protocol and Twitter Card.

  Typical usage:

  ```elixir
  defmodule Sample do
    use Markright.Collector, collectors: Markright.Collectors.OgpTwitter

    def on_ast(%Markright.Continuation{ast: {tag, _, _}} = cont), do: tag
  end
  ```

  ## Examples

  ```xml
  <meta name="twitter:card"        content="summary" />
  <meta property="og:type"         content="object" />

  <meta name="twitter:image:src"   property="og:image"       content="https://avatars2..." />
  <meta name="twitter:site"        property="og:site_name"   content="@github" />
  <meta name="twitter:title"       property="og:title"       content="TITLE" />
  <meta name="twitter:description" property="og:description" content="DESCRIPTION" />
  ```
  """

  @behaviour Markright.Collector

  def on_ast(%Markright.Continuation{ast: ast} = _cont, acc) do
    case ast do
      {:img, %{src: href}, _} -> Keyword.put_new(acc, :image, href)
      {:p, _, text}   -> Keyword.put_new(acc, :description, text)
      {:h1, _, text}  -> Keyword.put_new(acc, :title, text)
      {:h2, _, text}  -> Keyword.put_new(acc, :title2, text)
      _ -> acc
    end
  end

  def afterwards(acc, opts) do
    title = acc[:title] || acc[:title2]
    description = acc[:description]
    image = acc[:image]
    [
      {:meta, %{name: "twitter:card", content: "summary"}, nil},
      {:meta, %{property: "og:type", content: "object"}, nil},

      {:meta, %{name: "twitter:image:src", property: "og:image", content: image}, nil},
      {:meta, %{name: "twitter:site", property: "og:site_name", content: opts[:site] || "★★★"}, nil},
      {:meta, %{name: "twitter:title", property: "og:title", content: title}, nil},
      {:meta, %{name: "twitter:description", property: "og:description", content: description}, nil}
    ]
  end
end
