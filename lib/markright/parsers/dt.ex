defmodule Markright.Parsers.Dt do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = " item 1
      ...> ever
      ...> ▷ item 2
      ...> "
      iex> Markright.Parsers.Dt.to_ast(input)
      %Markright.Continuation{ast: [{:dt, %{}, "item 1"},
             {:dd, %{}, " ever"}], tail: "\n ▷ item 2\n "}

      iex> input = " item 1
      ...> *ever*
      ...> ▷ item 2
      ...> "
      iex> Markright.Parsers.Dt.to_ast(input)
      %Markright.Continuation{ast: [{:dt, %{}, "item 1"},
             {:dd, %{}, [" ", {:strong, %{}, "ever"}]}],
            tail: "\n ▷ item 2\n "}
  """

  use Markright.Helpers.Lead

end
