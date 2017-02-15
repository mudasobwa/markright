defmodule Markright.Collectors.OgpTwitter do
  @moduledoc ~S"""
  Collector that basically builds the Open Graph Protocol and Twitter Card.

  Typical usage:

  ```elixir
  defmodule
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

  def on_ast(%Markright.Continuation{} = cont, acc) do
    IO.puts "★★★ #{inspect cont}"
    acc ++ [:boom]
  end
end
