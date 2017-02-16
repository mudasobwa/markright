defmodule Markright.Collectors.Tag do
  @moduledoc ~S"""
  Collector for tags appeared in the content.
  """

  @behaviour Markright.Collector

  def on_ast(%Markright.Continuation{ast: ast} = _cont, acc) do
    case ast do
      {:a, %{class: "tag"}, tag} -> [tag | acc]
      _ -> acc
    end
  end

  def afterwards(acc, opts) do
    {:ul, %{class: "tags"}, Enum.map(acc, fn tag -> {:li, %{class: "tag"}, tag} end)}
  end
end
