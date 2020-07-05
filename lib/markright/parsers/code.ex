defmodule Markright.Parsers.Code do
  @moduledoc ~S"""
  Parses the input for the inline code snippet.
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume) when is_binary(input) do
    with %Plume{} = cont <- astify(input, plume) do
      Markright.Utils.continuation(cont, {:code, %{}})
    end
  end

  ##############################################################################

  @spec astify(String.t(), Markright.Continuation.t()) :: Markright.Continuation.t()
  defp astify(part, plume)

  ##############################################################################

  defp astify(<<"`"::binary, rest::binary>>, %Plume{} = plume),
    do: Plume.astail!(plume, rest)

  defp astify(<<letter::binary-size(1), rest::binary>>, %Plume{} = plume),
    do: astify(rest, Plume.tail!(plume, letter))

  defp astify("", %Plume{} = plume),
    do: Plume.astail!(plume)

  ##############################################################################
end
