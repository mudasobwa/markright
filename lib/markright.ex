defmodule Markright do
  @moduledoc """
  Custom syntax `Markdown`-like text processor.
  """

  @behaviour Markright.Parser

  import Markright.Utils, only: [sanitize_line_endings: 1]
  use Markright.Buffer, as: Buf


  @doc """
  Hello world.

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
  def to_ast(input, fun \\ nil, opts \\ %{}, _acc \\ Buf.empty())
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    input
    |> sanitize_line_endings
    |> Markright.Parsers.Article.to_ast(fun, Map.put(opts, :only, :ast))
  end

end
