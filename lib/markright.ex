defmodule Markright do
  @moduledoc """
  Custom syntax `Markdown`-like text processor.
  """

  @behaviour Markright.Parser

  import Markright.Utils, only: [sanitize_line_endings: 1]


  @doc """
  Hello world.

  ## Examples

      iex> Markright.to_ast("Plain string.")
      [{:p, %{}, "Plain string."}]

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
      {:p, %{}, ["Hello, ", {:strong, %{}, "world"}, "!"]}
      iex> Enum.at(ast, 1)
      {:blockquote, %{}, [
        " This is a ",
        {:em, %{}, "blockquote"},
        ".\n       It is multiline."
      ]}
      iex> Enum.at(ast, 2)
      {:p, %{}, ["Cordially, ", {:em, %{}, "Markright"}, "."] }

      iex> input = "plain *bold* rest!"
      iex> Markright.to_ast(input)
      [{:p, %{}, ["plain ", {:strong, %{}, "bold"}, " rest!"]}]

      iex> input = "plain *bold1* _italic_ *bold2* rest!"
      iex> Markright.to_ast(input)
      [{:p, %{}, ["plain ", {:strong, %{}, "bold1"}, " ", {:em, %{}, "italic"}, " ",
             {:strong, %{}, "bold2"}, " rest!"]}]

      iex> input = "plainplainplain *bold1bold1bold1* and *bold21bold21bold21 _italicitalicitalic_ bold22bold22bold22* rest!"
      iex> Markright.to_ast(input)
      [{:p, %{}, ["plainplainplain ", {:strong, %{}, "bold1bold1bold1"}, " and ",
             {:strong, %{},
              ["bold21bold21bold21 ", {:em, %{}, "italicitalicitalic"},
               " bold22bold22bold22"]}, " rest!"]}]

      iex> input = "_Please ~use~ love **`Markright`** since it is *great*_!"
      iex> Markright.to_ast(input)
      [{:p, %{}, [
        {:em, %{},
          ["Please ", {:strike, %{}, "use"}, " love ",
           {:b, %{}, {:code, %{}, "Markright"}}, " since it is ",
           {:strong, %{}, "great"}, ""]}, "!"]}]

      iex> input = "> Blockquotes!
      ...> > This is level 2."
      iex> Markright.to_ast(input, fn e -> IO.puts "★☆★ \#{inspect(e)}" end)
      [{:blockquote, %{}, [" Blockquote!", " This is level 2."]}]

      iex> input = "Unterminated *asterisk"
      iex> Markright.to_ast(input, fn e -> IO.puts "★☆★ \#{inspect(e)}" end)
      [{:p, %{}, ["Unterminated asterisk"]}]

      iex> input = "Escaped /*asterisk"
      iex> Markright.to_ast(input)
      [{:p, %{}, "Escaped *asterisk"}]

      iex> input = "Escaped \\\\*asterisk 2"
      iex> Markright.to_ast(input)
      [{:p, %{}, "Escaped *asterisk 2"}]


  """
  def to_ast(input, fun \\ nil, opts \\ %{}) when is_binary(input) and
                                                (is_nil(fun) or is_function(fun)) and
                                                 is_map(opts) do
    input
    |> sanitize_line_endings
    |> String.replace(~r/\n*(#{Markright.Syntax.blocks()})/, "\n\n\\1") # at least two CRs before
    |> String.split(~r/\n{2,}/)
    |> Stream.map(& &1 |> String.trim |> Markright.Parser.Generic.to_ast(fun, opts))
    |> Enum.to_list
  end

end
