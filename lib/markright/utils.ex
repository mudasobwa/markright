defmodule Markright.Utils do

  ##############################################################################

  defmacro is_empty(nil), do: true
  defmacro is_empty(""), do: true
  defmacro is_empty([]), do: true
  defmacro is_empty({}), do: true
  defmacro is_empty(%{}), do: true
  defmacro is_empty({_, _, ""}), do: true

#  defmacro is_empty(list) when is_list(list), do: Enum.all?(list, &is_empty/1)
#  defmacro is_empty(map) when is_map(map), do: Enum.all?(map, fn
#    v -> is_empty(v)
#    {_, v} -> is_empty(v)
#  end)
#  defmacro is_empty(arg1, arg2) when is_empty(arg1) and is_empty(arg2), do: true
  defmacro is_empty(_), do: false
  defmacro is_empty(_, _), do: false
  defmacro is_empty(_, _, _), do: false

  def clean!({_tag, _opts, ast}) when is_empty(ast), do: []
  def clean!(ast) when is_list(ast), do: Enum.filter(ast, &(not is_empty(&1)))
  def clean!(anything), do: anything
  def join!(asts) when is_list(asts) do
    IO.inspect(asts)
    asts
    |> Enum.map(& clean!/1)
    |> clean!
    |> Enum.reduce([], fn e, acc ->
      IO.puts("★★★ ★★★ #{inspect(e)}")
      unless is_empty(e), do: acc ++ [e], else: acc
    end)
  end

  ##############################################################################

  # def leavify({head, tail}) when is_empty(head), do: tail
  # def leavify({head, tail}) when is_empty(tail), do: head
  def leavify({head, tail}), do: [head, tail]

  def leavify(leaves) when is_list(leaves) do
    case Enum.filter(leaves, fn
                               e when is_binary(e) -> String.trim(e) != ""
                              _ -> true
                             end) do
      []  -> ""
      %{} -> ""
      [h] -> h
      _   -> leaves
    end
  end

  def deleavify(input) do
    case input do
      s when "" == s      -> []
      s when is_binary(s) -> [s]
      s when is_list(s)   -> s
      t when is_tuple(t)  -> [t] # NOT Tuple.to_list(t)
      _                   -> [input]
    end
  end

  ##############################################################################

  @spec to_module_name(Atom.t, List.t) :: Atom.t
  def to_module(atom, opts \\ [prefix: Markright.Parsers, fallback: Markright.Parsers.Generic]) do
    mod = to_module_name(atom, [prefix: opts[:prefix]])
    if Code.ensure_loaded?(mod), do: mod, else: opts[:fallback]
  end

  @spec to_module_name(Atom.t, List.t) :: Atom.t
  defp to_module_name(atom, opts) do
    if String.starts_with?("#{atom}", "Elixir.") do
      atom
    else
      mod = atom
            |> to_string
            |> String.downcase
            |> camelize
      if is_atom(opts[:prefix]), do: Module.concat(opts[:prefix], mod), else: mod
    end
  end

  defp camelize(str) when is_binary(str) do
    Regex.replace(~r/(?:_|\A)(.)/, str, fn _, m -> String.upcase(m) end)
  end

  ##############################################################################

  def sanitize_line_endings(input) do
    Regex.replace(~r/\r\n|\r/, input, "\n")
  end

  ##############################################################################

end
