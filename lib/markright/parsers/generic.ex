defmodule Markright.Parsers.Generic do
  @moduledoc ~S"""
  The generic, aka topmost, aka multi-purpose parser, used when
  there is no specific parser declared for the tag.
  """

  use Markright.WithSyntax
end
