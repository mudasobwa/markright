defmodule Markright.Parsers.Tag do
  @moduledoc ~S"""
  Parses the input for the line item.

  ## Examples

      iex> input = "#item1 something"
      iex> Markright.Parsers.Tag.to_ast(input)
      %Markright.Continuation{ast: {:a, %{class: "tag", href: "/tags/item1"}, "item1"}, tail: " something"}
  """

  use Markright.Helpers.Magnet

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    %Markright.Continuation{ast: <<@magnet :: binary, tag :: binary>>} = cont = astify(input)
    Markright.Utils.continuation(:continuation,
                                  %Markright.Continuation{cont | ast: tag},
                                  {:a, %{class: "tag", href: "/tags/#{tag}"}, fun})
  end
end
