defmodule Markright.Utils do

  ##############################################################################

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

  def sanitize_line_endings(input) do
    Regex.replace(~r/\r\n|\r/, input, "\n")
  end

  ##############################################################################

end
