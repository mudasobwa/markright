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
      {{:pre, %{}, [{:code, %{lang: "ruby"}, " $ ls -la"}]},
            "\n Other text.\n "}

      iex> input = "
      ...> $ ls -la
      ...> ```
      ...> Other text.
      ...> "
      iex> Markright.Parsers.Code.to_ast(input)
      {{:pre, %{}, [{:code, %{}, " $ ls -la"}]},
            "\n Other text.\n "}
  """
  @behaviour Markright.Parser

  use Markright.Buffer

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty()) \
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    {lang, rest} = Markright.Parsers.Word.to_ast(input)
    {code, rest} = astify(rest, fun, opts, acc)
    {{:pre, opts, [
      {:code,
        (if String.trim(lang) == "", do: %{}, else: %{lang: lang}),
        code}]}, rest}
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc)

  ##############################################################################

  Enum.each(0..4, fn i ->
    indent = String.duplicate(" ", i)
    defp astify(<<"\n" :: binary, unquote(indent) :: binary, "```" :: binary, rest :: binary>>, _fun, _opts, acc),
      do: {acc.buffer, rest}
    end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  ##############################################################################
end
