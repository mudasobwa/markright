defmodule Markright.Collectors.Fuerer do
  @moduledoc ~S"""
  Collector that converts the topmost para into h2 tag unless it’s set.
  ```
  """

  @behaviour Markright.Collector

  @empty_header "★ ★ ★"

  def on_ast(%Markright.Continuation{ast: ast} = _cont, acc) do
    case ast do
      {:article, %{}, [{tag, _, text} | _]}
        when tag == :p or tag == :h1 or tag == :h2 or tag == :h3 ->
          Keyword.put_new(acc, :header, text)
      _ -> acc
    end
  end

  def afterwards(acc, opts) do
    acc = Keyword.put_new(acc, :header, @empty_header)
    {:h2, opts[:attrs] || %{}, acc[:header]}
  end
end
