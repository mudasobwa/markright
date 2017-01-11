defmodule Markright do
  @moduledoc """
  Custom syntax `Markdown`-like text processor.
  """

  @behaviour Markright.Parser

  @doc """
  Main application helper: call
  `Markright.to_ast(input, fn {ast, tail} -> IO.inspect(ast) end)`
  to transform the markright into the AST, optionally being called back
  on every subsequent transform.

  ## Examples

      iex> Markright.to_ast("Plain string.")
      {:article, %{}, [{:p, %{}, "Plain string."}]}

      iex> input = "plain *bold* rest!"
      iex> Markright.to_ast(input)
      {:article, %{}, [{:p, %{}, ["plain ", {:strong, %{}, "bold"}, " rest!"]}]}

      iex> input = "plain *bold1* _italic_ *bold2* rest!"
      iex> Markright.to_ast(input)
      {:article, %{},
        [{:p, %{}, ["plain ", {:strong, %{}, "bold1"}, " ", {:em, %{}, "italic"}, " ",
           {:strong, %{}, "bold2"}, " rest!"]}]}

      iex> input = "plainplainplain *bold1bold1bold1* and *bold21bold21bold21 _italicitalicitalic_ bold22bold22bold22* rest!"
      iex> Markright.to_ast(input)
      {:article, %{},
        [{:p, %{}, ["plainplainplain ", {:strong, %{}, "bold1bold1bold1"}, " and ",
             {:strong, %{},
              ["bold21bold21bold21 ", {:em, %{}, "italicitalicitalic"},
               " bold22bold22bold22"]}, " rest!"]}]}

      iex> input = "_Please ~use~ love **`Markright`** since it is *great*_!"
      iex> Markright.to_ast(input)
      {:article, %{},
        [{:p, %{}, [
          {:em, %{},
            ["Please ", {:strike, %{}, "use"}, " love ",
             {:b, %{}, [{:code, %{}, "Markright"}]}, " since it is ",
             {:strong, %{}, "great"}]}, "!"]}]}

      iex> input = "Escaped /*asterisk"
      iex> Markright.to_ast(input)
      {:article, %{}, [{:p, %{}, "Escaped *asterisk"}]}

      iex> input = "Escaped \\\\*asterisk 2"
      iex> Markright.to_ast(input)
      {:article, %{}, [{:p, %{}, "Escaped *asterisk 2"}]}


  """
  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %Markright.Continuation{ast: ast} <- Markright.Parsers.Article.to_ast(input, fun, opts) do
      ast
    end
  end

  @doc """
  Most shame part of this package: here we use `Regex` because, you know, fuck Windows.

  @fixme
  """
  def to_ast_safe_input(input, fun \\ nil, opts \\ %{}) do
    to_ast(Regex.replace(~r/\r\n|\r/, input, "\n"), fun, opts)
  end

end
