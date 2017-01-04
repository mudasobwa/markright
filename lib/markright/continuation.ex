defmodule Markright.Continuation do
  @fields [ast: %{}, rest: ""]

  def fields, do: @fields

  defstruct @fields
end
