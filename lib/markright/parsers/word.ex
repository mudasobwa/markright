defmodule Markright.Parsers.Word do
  @moduledoc ~S"""
  Parses the input until the first occurence of a space.

  ## Examples

      iex> "Hello my lovely world!" |> Markright.Parsers.Word.to_ast()
      %Markright.Continuation{ast: "Hello", tail: "my lovely world!"}
  """

  ##############################################################################

  use Markright.Continuation
  use Markright.Helpers.Magnet

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
      cont = astify(input, plume)
      if plume.bag[:notrim],
        do: cont,
        else: %Plume{cont | tail: String.trim(cont.tail)}
  end

  ##############################################################################
end
