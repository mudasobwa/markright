defmodule Markright do
  @moduledoc """
  Custom syntax `Markdown`-like text processor.
  """

  @max_lookahead 10

  defmodule Markright.Syntax do
    @syntax [
      block: [
        blockquote: ">"
      ],
      flush: [

      ],
      grip: [
        em: "_",
        strong: "*"
      ]
    ]

    def syntax do
      config = Application.get_env(:markright, :syntax) || []
      Keyword.merge(config, @syntax, fn _k, v1, v2 ->
        Keyword.merge(v1, v2)
      end)
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> input = "Hello, *world*!
      ...>
      ...> > This is a _blockquote_.
      ...>   It is multiline.
      ...>
      ...> Cordially, _Markright_."
      iex> ast = Markright.to_ast(input)
      iex> Enum.count(ast)
      3
      iex> Enum.at(ast, 0)
      [{:text, [], "Hello, "}, {:strong, [], "world"}, {:text, [], "!"}]
      iex> Enum.at(ast, 1)
      {:blockquote, [], [
        {:text, [], " This is a "},
        {:em, [], "blockquote"},
        {:text, [], ".\n       It is multiline."}
        ]
      }
      iex> Enum.at(ast, 2)
      [{:text, [], "Cordially, "}, {:em, [], "Markright"}, {:text, [], "."}]

      iex> input = "Hello, *_great_ world*!"
      iex> Markright.to_ast(input)
      [{:text, [], "Hello, *world!"}]


  """
  def to_ast(input, fun \\ nil, opts \\ []) when is_binary(input) and
                                                (is_nil(fun) or is_function(fun)) and
                                                 is_list(opts) do
    input
    |> sanitize_line_endings
    |> String.replace(~r/\n*(#{blocks()})/, "\n\n\\1") # at least two CRs before
    |> String.split(~r/\n{2,}/)
    |> Stream.map(& &1 |> String.trim |> astify(fun, opts))
    |> Enum.to_list
  end

  ##############################################################################

  defp blocks do
    Markright.Syntax.syntax()[:block]
    |> Keyword.values
    |> Enum.map(& "\n[\s\t]*" <> &1)
#    |> Enum.map(& Regex.escape/1) # We DO NOT escape to allow regexps
    |> Enum.join("|")
  end

  defp sanitize_line_endings(input) do
    Regex.replace(~r/\r\n|\r/, input, "\n")
  end

  ##############################################################################

  defp flush(acc, tag, opts) do
    case acc do
      [{^tag, opts, buffer} | t] ->
        {{tag, opts, buffer}, t}
      [{:text, opts, buffer} | t] ->
        {{:text, opts, buffer}, [{tag, opts, ""}] ++ t}
      _ ->
        {:tag, [{tag, opts, ""}] ++ acc}
    end
  end

  defp astify(part, fun, opts, acc \\ [])
  defp astify(<<">"  :: binary, rest :: binary>>, fun, opts, acc) do
    result = {:blockquote, opts, astify(rest, fun, opts, acc)}
    if fun, do: fun.(result)
    result
  end

  Enum.each(0..@max_lookahead-1, fn i ->
    Enum.each(Markright.Syntax.syntax()[:grip], fn {t, g} ->
      Code.eval_string(~s"""
        defp astify(<<plain :: binary-size(#{i}), "#{g}" :: binary, rest :: binary>>, fun, opts, acc) do
          acc = case acc do
            [] -> [{:text, opts, plain}]
            [{tag, opts, buffer} | t] -> [{tag, opts, buffer <> plain}] ++ t
          end
          result = case flush(acc, :#{t}, opts) do
                     {:tag, neu} ->
                       astify(rest, fun, opts, neu)
                     {{tag, opts, buffer}, neu} ->
                       [{tag, opts, buffer}] ++ astify(rest, fun, opts, neu)
                   end
          if fun, do: fun.(result)
          result
        end
      """, [], __ENV__)
    end)
  end)

  defp astify(<<plain :: binary-size(@max_lookahead), rest :: binary>>, fun, opts, acc) do
    case acc do
      [{tag, opts, buffer} | t] ->
        astify(rest, fun, opts, [{tag, opts, buffer <> plain}] ++ t)
      [] ->
        astify(rest, fun, opts, [{:text, opts, plain}])
    end
  end

  ##############################################################################
  ### MUST BE LAST
  ##############################################################################

  defp astify(unmatched, fun, opts, acc) when is_binary(unmatched) do
    result = case acc do
               [{tag, opts, buffer} | t] -> [{tag, opts, buffer <> unmatched}] # ++ astify() ???
               [] -> [{:text, opts, unmatched}]
             end
    if fun, do: fun.(result)
    result
  end
end
