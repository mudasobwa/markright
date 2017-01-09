defmodule Markright.Parsers.Code do
  @moduledoc ~S"""
  Parses the input for the code block.

  ## Examples

      iex> input = "ruby
      ...> $ ls -la
      ...> ```
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Code.to_ast(input)
      %Markright.Continuation{
        ast: {:pre, %{}, [{:code, %{lang: "ruby"}, " $ ls -la"}]},
        tail: "\n Other text.\n "}

      iex> input = "
      ...> $ ls -la
      ...> ```
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Code.to_ast(input)
      %Markright.Continuation{
        ast: {:pre, %{}, [{:code, %{}, " $ ls -la"}]}, tail: "\n Other text.\n "}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  @max_indent Markright.Syntax.indent

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    %C{ast: lang, tail: tail} = Markright.Parsers.Word.to_ast(input)
    with %C{ast: code, tail: rest} <- astify(tail, fun, opts, Buf.empty()) do
      %C{ast: {:pre, opts, [{:code, (if String.trim(lang) == "", do: %{}, else: %{lang: lang}), code}]}, tail: rest}
    end
    |> C.callback(fun)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(0..@max_indent-1, fn i ->
    indent = String.duplicate(" ", i)
    defp astify(<<"\n" :: binary, unquote(indent) :: binary, "```" :: binary, rest :: binary>>, _fun, _opts, acc) do
      Logger.debug "★ CODE ★ #{rest}"
      %C{ast: acc.buffer, tail: rest}
    end
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  defp astify("", _fun, _opts, acc),
    do: %C{ast: acc.buffer, tail: ""}

  ##############################################################################
end
