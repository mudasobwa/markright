defmodule Markright do
  @moduledoc """
  Custom syntax `Markdown`-like text processor.
  """

  @max_lookahead 10

  defmodule Syntax do
    @syntax [
      block: [
        blockquote: ">"
      ],
      flush: [

      ],
      grip: [
        em: "_",
        strong: "*",
        b: "**",
        code: "`",
        strike: "~",
      ]
    ]

    def syntax do
      config = Application.get_env(:markright, :syntax) || []
      Keyword.merge(config, @syntax, fn _k, v1, v2 ->
        Keyword.merge(v1, v2)
      end)
    end

    def blocks do
      syntax()[:block]
      |> Keyword.values
      |> Enum.map(& "\n[\s\t]*" <> &1)
  #    |> Enum.map(& Regex.escape/1) # We DO NOT escape to allow regexps
      |> Enum.join("|")
    end

    def grips do
      syntax()[:grip]
      |> Enum.sort(fn {_, v1}, {_, v2} -> String.length(v1) > String.length(v2) end)
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
      {:p, [], ["Hello, ", {:strong, [], "world"}, "!"]}
      iex> Enum.at(ast, 1)
      {:blockquote, [], [
        " This is a ",
        {:em, [], "blockquote"},
        ".\n       It is multiline."
      ]}
      iex> Enum.at(ast, 2)
      {:p, [], ["Cordially, ", {:em, [], "Markright"}, "."] }

      iex> input = "plain *bold* rest!"
      iex> Markright.to_ast(input)
      [{:p, [], ["plain ", {:strong, [], "bold"}, " rest!"]}]

      iex> input = "plain *bold1* _italic_ *bold2* rest!"
      iex> Markright.to_ast(input)
      [{:p, [], ["plain ", {:strong, [], "bold1"}, " ", {:em, [], "italic"}, " ",
             {:strong, [], "bold2"}, " rest!"]}]

      iex> input = "plainplainplain *bold1bold1bold1* and *bold21bold21bold21 _italicitalicitalic_ bold22bold22bold22* rest!"
      iex> Markright.to_ast(input)
      [{:p, [], ["plainplainplain ", {:strong, [], "bold1bold1bold1"}, " and ",
             {:strong, [],
              ["bold21bold21bold21 ", {:em, [], "italicitalicitalic"},
               " bold22bold22bold22"]}, " rest!"]}]

      iex> input = "_Please ~use~ love **`Markright`** since it is *great*_!"
      iex> Markright.to_ast(input, fn e -> IO.puts "★☆★ \#{inspect(e)}" end)
      [{:p, [], [
        {:em, [],
          ["Please ", {:strike, [], "use"}, " love ",
           {:b, [], {:code, [], "Markright"}}, " since it is ",
           {:strong, [], "great"}, ""]}, "!"]}]

      iex> input = "> Welcome b> ack! >> This is level 2."
      iex> Markright.to_ast(input, fn e -> IO.puts "★☆★ \#{inspect(e)}" end)
      [{:p, [], []}]


  """
  def to_ast(input, fun \\ nil, opts \\ []) when is_binary(input) and
                                                (is_nil(fun) or is_function(fun)) and
                                                 is_list(opts) do
    input
    |> sanitize_line_endings
    |> String.replace(~r/\n*(#{Markright.Syntax.blocks()})/, "\n\n\\1") # at least two CRs before
    |> String.split(~r/\n{2,}/)
    |> Stream.map(& &1 |> String.trim |> astify(fun, opts))
    |> Enum.to_list
  end

  ##############################################################################

  defp sanitize_line_endings(input) do
    Regex.replace(~r/\r\n|\r/, input, "\n")
  end

  defmacrop is_empty_buffer(data) do
    quote do: %Markright.Buffer{buffer: "", tags: []} == unquote(data)
  end

  ##############################################################################

  @spec callback_through(Tuple.t, Function.t, Markright.Buffer.t | String.t) :: any
  defp callback_through(ast, fun \\ nil, rest \\ nil)
  defp callback_through(ast, nil, nil), do: ast
  defp callback_through(ast, nil, rest) when is_binary(rest), do: {ast, rest}
  defp callback_through(ast, nil, %Markright.Buffer{} = rest), do: {ast, rest.buffer}
  defp callback_through(ast, fun, rest) when is_function(fun, 1) do
    fun.({ast, rest})
    callback_through(ast, nil, rest)
  end
  defp callback_through(ast, fun, rest) when is_function(fun, 2) do
    fun.(ast, rest)
    callback_through(ast, nil, rest)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Markright.Buffer.t) :: any
  defp astify(part, fun, opts, acc \\ %Markright.Buffer{})

  defp astify(<<">"  :: binary, rest :: binary>>, fun, opts, acc) when is_empty_buffer(acc) do
    callback_through({:blockquote, opts, astify(rest, fun, opts, Markright.Buffer.unshift(acc, {:blockquote, []}))}, fun)
  end

  defp astify(input, fun, opts, acc) when is_binary(input) and is_empty_buffer(acc) do
    callback_through({:p, opts, astify(input, fun, opts, Markright.Buffer.unshift(acc, {:p, []}))}, fun)
  end


  Enum.each(0..@max_lookahead-1, fn i ->
    Enum.each(Markright.Syntax.grips(), fn {t, g} ->
      defp astify(<<plain :: binary-size(unquote(i)), unquote(g) :: binary, rest :: binary>>, fun, opts, acc) do
        case Markright.Buffer.shift(acc) do
          {{unquote(t), opts}, tail} ->
            [astify(plain, fun, opts, acc), {rest, Markright.Buffer.cleanup(tail)}]

          other ->
            neu = Markright.Buffer.unshift(acc, {unquote(t), opts})
            astified = astify(rest, fun, opts, Markright.Buffer.cleanup(neu))
            {ready, [{tbd, tail}]} = Enum.split(astified, -1)
            rest = astify(tbd, fun, opts, tail)
            case astify(plain, fun, opts, acc) do
              s when "" == s -> []
              s             -> [s]
            end ++ [
              callback_through({unquote(t), opts, normalize_leaves(ready)}, fun)
            ] ++ (if is_list(rest), do: rest, else: [rest])
        end
      end
    end)
  end)

  defp astify(<<plain :: binary-size(@max_lookahead), rest :: binary>>, fun, opts, acc) do
    astify(rest, fun, opts, Markright.Buffer.append(acc, plain))
  end

  ##############################################################################
  ### MUST BE LAST
  ##############################################################################

  defp astify(unmatched, _fun, _opts, acc) when is_binary(unmatched) do
    Markright.Buffer.append(acc, unmatched).buffer
  end

  ##############################################################################

  defp normalize_leaves(leaves) when is_list(leaves) do
    case Enum.filter(leaves, fn
                               e when is_binary(e) -> String.trim(e) != ""
                               _ -> true
                             end) do
      []  -> ""
      [h] -> h
      _   -> leaves
    end
  end
end
