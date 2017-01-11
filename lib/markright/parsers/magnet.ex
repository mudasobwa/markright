  defmodule Markright.Parsers.Magnet do
    use Markright.Helpers.Magnet, magnet: "http", tag: :a, attr: :href
  end
