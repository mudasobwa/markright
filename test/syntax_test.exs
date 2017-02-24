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

  test "treats <br> normally" do
    input = """
    Line one.  
    Line two.
    """
    assert Markright.to_ast(input) == {:article, %{}, [{:p, %{}, ["Line one.", {:br, %{}, nil}, "Line two.\n"]}]}
  end

  test "treats <ul> normally" do
    input = """
    **Часть 1. Пришествие рядового Разнобердыева**

    - Первый звонок
    - Шестое кольцо
    - Второй завтрак
    """
    output = {:article, %{}, [
                {:p, %{}, [
                  {:b, %{}, "Часть 1. Пришествие рядового Разнобердыева"},
                  {:ul, %{}, [
                    {:li, %{}, "Первый звонок"},
                    {:li, %{}, "Шестое кольцо"},
                    {:li, %{}, "Второй завтрак"}]}]}]}
    assert Markright.to_ast(input) == output
  end

  test "treats <h4> normally" do
    input = """
    ### Часть 1. Section

    #### Часть 1.1. Subsection

    - Первый звонок
    - Шестое кольцо
    - Второй завтрак
    """
    output = {:article, %{}, [
                {:h3, %{}, "Часть 1. Section"},
                {:h4, %{}, "Часть 1.1. Subsection"},
                {:ul, %{}, [
                  {:li, %{}, "Первый звонок"},
                  {:li, %{}, "Шестое кольцо"},
                  {:li, %{}, "Второй завтрак"}]}]}
    assert Markright.to_ast(input) == output
  end

  @tag :skip
  test "converts text" do
    input = "test/fixtures/rr.md"
            |> File.read!
            |> Markright.to_ast
            |> XmlBuilder.generate
    expected = File.read! "test/fixtures/rr.html"
    assert expected == input
  end

end
