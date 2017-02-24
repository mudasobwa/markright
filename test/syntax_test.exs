defmodule Markright.Syntax.Test do
  use ExUnit.Case
  doctest Markright.Syntax

  @input ~S"""
  Hello world.

  > my blockquote

  Right after.
  Normal *para* again.
  """

  @output {:article, %{}, [
    {:p, %{}, "Hello world."},
     {:div, %{class: "blockquote"}, ["my blockquote"]},
     {:p, %{},
      ["Right after.\nNormal ", {:strong, %{}, "para"}, " again."]}]}

  @tag :skip
  test "understands codeblock in the markright" do
    assert Markright.to_ast(@input) == @output
  end

end
