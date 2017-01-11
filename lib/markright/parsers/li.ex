defmodule Markright.Parsers.Li do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = " item 1
      ...> ever
      ...> - item 2
      ...> "
      iex> Markright.Parsers.Li.to_ast(input)
      %Markright.Continuation{ast: {:li, %{}, "item 1\n ever"}, tail: "\n - item 2\n "}

      iex> input = " item 1
      ...> *ever*
      ...> - item 2
      ...> "
      iex> Markright.Parsers.Li.to_ast(input)
      %Markright.Continuation{ast: {:li, %{}, ["item 1\n ", {:strong, %{}, "ever"}]}, tail: "\n - item 2\n "}
  """

  use Markright.Helpers.Lead
  
end
