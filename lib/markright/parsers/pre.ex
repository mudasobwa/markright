defmodule Markright.Parsers.Pre do
  @moduledoc ~S"""
  Parses the input for the code block.

  ## Examples

      iex> input = "ruby
      ...> $ ls -la
      ...> ```
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Pre.to_ast(input)
      %Markright.Continuation{
        ast: {:pre, %{}, [{:code, %{lang: "ruby"}, "$ ls -la"}]},
        tail: "\n Other text."}

      iex> input = "
      ...> $ ls -la
      ...> ```
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Pre.to_ast(input)
      %Markright.Continuation{
        ast: {:pre, %{}, [{:code, %{}, "$ ls -la"}]}, tail: "\n Other text."}

      iex> input = "elixir
      ...> def f(\"\"), do: :empty_string
      ...>
      ...> def f([]), do: :empty_list
      ...> ```
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Pre.to_ast(input)
      %Markright.Continuation{ast: {:pre, %{},
             [{:code, %{lang: "elixir"},
               "def f(\"\"), do: :empty_string\n\n def f([]), do: :empty_list"}]},
            tail: "\n Other text."}
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
    with %Plume{ast: lang, tail: tail} <- Markright.Parsers.Word.to_ast(input, plume),
         %Plume{ast: code, tail: rest} <- astify(tail, plume) do
      code_opts = if Markright.Utils.empty?(lang), do: %{}, else: %{lang: lang}
      # TODO: Should we fire another continuation event on `code` explicitly?
      Markright.Utils.continuation(
        %Plume{plume | ast: [{:code, code_opts, code}], tail: rest},
        {:pre, %{}}
      )
    end
  end

  ##############################################################################

  @spec astify(String.t(), Markright.Continuation.t()) :: Markright.Continuation.t()
  defp astify(part, plume)

  ##############################################################################

  Enum.each(0..(@max_indent - 1), fn i ->
    indent = String.duplicate(" ", i)
    {tag, _handler} = Markright.Syntax.get(:block, :pre)

    defp astify(
           <<
             @unix_newline::binary,
             unquote(indent)::binary,
             unquote(tag)::binary,
             rest::binary
           >>,
           %Plume{} = plume
         ) do
      Plume.astail!(plume, rest)
    end
  end)

  defp astify(<<letter::binary-size(1), rest::binary>>, %Plume{} = plume),
    do: astify(rest, Plume.tail!(plume, letter))

  defp astify("", %Plume{} = plume), do: Plume.astail!(plume)

  ##############################################################################
end
