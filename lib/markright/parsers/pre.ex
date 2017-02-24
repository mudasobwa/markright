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

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: lang, tail: tail} <- Markright.Parsers.Word.to_ast(input),
         %C{ast: code, tail: rest} <- astify(tail, fun) do
      code_opts = if Markright.Utils.empty?(lang), do: %{}, else: %{lang: lang}
      # TODO: Should we fire another continuation event on `code` explicitly?
      Markright.Utils.continuation(%C{ast: [{:code, code_opts, code}], tail: rest}, {:pre, opts, fun})
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)
    {tag, handler} = Markright.Syntax.get(:block, :pre)
    defp astify(<<
                  @unix_newline :: binary,
                  unquote(indent) :: binary,
                  unquote(tag) :: binary,
                  rest :: binary
                >>, _fun, acc) do
      %C{ast: acc.buffer, tail: rest}
    end
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
    do: astify(rest, fun, Buf.append(acc, letter))

  defp astify("", _fun, acc),
    do: %C{ast: acc.buffer, tail: ""}

  ##############################################################################
end
