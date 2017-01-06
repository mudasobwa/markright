defmodule Markright.Utils do

  ##############################################################################

  defmacro empty_tag?({_, _, value}) do
    is_nil(value) || \
      (is_binary(value) && value == "") || \
      (is_list(value) && Enum.empty?(value)) #  || Enum.all?(&Markright.Utils.empty_tag?/1))
  end

  ##############################################################################

  # def leavify({head, tail}) when empty_tag?(head), do: tail
  def leavify({head, tail}) when empty_tag?(tail), do: head
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
  defp to_module_name(atom, opts \\ [prefix: Markright.Parsers]) do
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
