defmodule Markright.Parsers.Blockquote do
  @moduledoc ~S"""
  Parses the input for the blockquote block.

  ## Examples

      iex> input = "Hello
      ...> — _world_!
      ...>
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Blockquote.to_ast(input)
      %Markright.Continuation{
        ast: {:blockquote, %{}, [
          "Hello\n — ", {:em, %{}, "world"}, "!"]},
        tail: " Other text.\n "}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  @max_indent Markright.Syntax.indent()

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    with %Plume{ast: ast, tail: tail} <- astify(input, plume),
         plume <- plume |> Plume.untail!(),
         %Plume{ast: block, tail: ""} <- apply(plume.bag[:parser], :to_ast, [ast, plume]),
         do:
           Markright.Utils.continuation(
             %Plume{plume | ast: block, tail: tail},
             {:blockquote, %{}}
           )
  end

  ##############################################################################

  @spec astify(String.t(), Markright.Continuation.t()) :: Markright.Continuation.t()
  defp astify(part, plume)

  ##############################################################################

  defp astify(
         <<
           unquote(@splitter)::binary,
           rest::binary
         >>,
         %Plume{} = plume
       ),
       do: Plume.astail!(plume, rest)

  Enum.each(0..(@max_indent - 1), fn i ->
    indent = String.duplicate(" ", i)
    # FIXME!!!
    {tag, _handler} = Markright.Syntax.block()[:blockquote]

    defp astify(
           <<
             @unix_newline::binary,
             unquote(indent)::binary,
             unquote(tag)::binary,
             rest::binary
           >>,
           %Plume{} = plume
         ) do
      astify(" " <> rest, plume)
    end
  end)

  defp astify(<<letter::binary-size(1), rest::binary>>, %Plume{} = plume),
    do: astify(rest, Plume.tail!(plume, letter))

  defp astify("", %Plume{} = plume),
    do: Plume.astail!(plume, "")

  ##############################################################################
end
