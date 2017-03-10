defmodule Markright do
  @moduledoc """
  Custom syntax `Markdown`-like text processor.
  """

  @behaviour Markright.Parser

  alias Markright.Continuation, as: Plume

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
  def to_ast(input, fun_or_collector \\ nil, opts \\ %{})

  def to_ast(input, fun, opts)
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with plume <- %Plume{fun: fun},
        %Plume{ast: ast} <- Markright.Parsers.Article.to_ast(input, plume),
      do: ast
  end

  def to_ast(input, collector, opts)
    when is_binary(input) and is_atom(collector) and is_map(opts) do

    apply(collector, :start_link, [])
    fun = apply(collector, :on_ast_callback, [])

    ast = to_ast(input, fun, opts)
    collected = apply(collector, :ast_collected, [])
    afterwards = apply(collector, :afterwards, [collected])

    {ast, afterwards}
  after
    apply(collector, :stop, [])
  end

  @doc """
  Most shame part of this package: here we use `Regex` because, you know, fuck Windows.

  @fixme
  """
  def to_ast_safe_input(input, fun \\ nil, opts \\ %{}) do
    to_ast(Regex.replace(~r/\r\n|\r/, input, "\n"), fun, opts)
  end

  ##############################################################################

  def main(args) do
    args |> parse_args |> process
  end

  def process([]) do
    IO.puts "Usage: markright --file=filename.md"
  end

  def process(options) do
    if File.exists?(options[:file]) do
      result = options[:file]
               |> File.read!
               |> to_ast
               |> XmlBuilder.generate
      # result = if options[:squeeze], do: result |> String.split |> Enum.join(" "), else: result
      if options[:silent], do: result, else: IO.inspect(result)
    else
      IO.puts "Unable to read file #{options[:file]}"
    end
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [file: :string]
    )
    options
  end
end
