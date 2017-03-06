defmodule Markright.Parsers.Tag do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = "#item1 something"
      iex> Markright.Parsers.Tag.to_ast(input)
      %Markright.Continuation{ast: {:a, %{class: "tag", href: "/tags/item1"}, "item1"}, tail: " something"}
  """

  use Markright.Continuation
  use Markright.Helpers.Magnet

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    %Plume{ast: <<@magnet :: binary, tag :: binary>>} = cont = astify(input, plume)
    Markright.Utils.continuation(:continuation,
                                  %Plume{cont | ast: tag},
                                  {:a, %{class: "tag", href: "/tags/#{tag}"}})
  end
end
