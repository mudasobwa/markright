defmodule Markright.Parsers.Magnet do
  @moduledoc ~S"""
  The default magnet implementation, unsure if needed.
  """
  use Markright.Helpers.Magnet, tag: :a, attr: :href
end
