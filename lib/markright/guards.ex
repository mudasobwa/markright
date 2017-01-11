defmodule Markright.Guards do
  def empty?(nil), do: true
  def empty?(""), do: true
  def empty?([]), do: true
  def empty?({}), do: true
  def empty?(%{}), do: true
  def empty?({_, _, ""}), do: true
  def empty?({_, _, []}), do: true

  def empty?(list) when is_list(list), do: Enum.all?(list, &empty?/1)
  def empty?(map) when is_map(map), do: Enum.all?(map, fn
    {_, v} -> empty?(v)
    v -> empty?(v)
  end)
  def empty?(_), do: false
  def empty?(arg1, arg2), do: empty?(arg1) and empty?(arg2)
  def empty?(arg1, arg2, arg3), do: empty?(arg1, arg2) and empty?(arg3)

  ##############################################################################

  def squeeze!(ast, flatten \\ true)
  def squeeze!({ast1, ast2}, flatten), do: {squeeze!(ast1, flatten), squeeze!(ast2, flatten)}
  def squeeze!({tag, opts, ast}, flatten), do: {tag, opts, squeeze!(ast, flatten)}
  def squeeze!(ast, flatten) when is_list(ast) do
    Enum.reduce(ast, [], fn e, acc ->
      cond do
        empty?(e)  -> acc
        is_list(e) -> acc ++ (if flatten, do: squeeze!(e), else: [squeeze!(e)])
        true       -> acc ++ [e]
      end
    end)
    |> unlist
  end
  def squeeze!(anything, _flatten), do: if empty?(anything), do: [], else: anything

  ##############################################################################

  defp unlist([string]) when is_binary(string), do: string
  defp unlist(anything), do: anything
end
