defmodule Markright.Syntax.Test do
  @moduledoc false
  use ExUnit.Case
  doctest Markright.Syntax

  @input ~S"""
  Hello world.

  > my blockquote

  Right _after_.
  Normal *para* again.
  """

  @output {:article, %{}, [
    {:p, %{}, "Hello world."},
     {:blockquote, %{}, " my blockquote"},
     {:p, %{},
      ["Right ",
        {:em, %{}, "after"},
        ".\nNormal ",
        {:strong, %{}, "para"}, " again.\n"]}]}

  test "understands codeblock in the markright" do
    assert Markright.to_ast(@input) == @output
  end

  @empty_syntax []
  @output_empty_syntax {:article, %{}, [
    {:p, %{}, "Hello world."},
    {:p, %{}, "> my blockquote"},
    {:p, %{}, "Right _after_.\nNormal *para* again.\n"}]}

  test "works with empty syntax" do
    assert Markright.to_ast(@input, nil, syntax: @empty_syntax) == @output_empty_syntax
  end

  @simple_syntax [grip: [em: "_", strong: "*"]]
  @output_simple_syntax {:article, %{}, [
    {:p, %{}, "Hello world."},
    {:p, %{}, "> my blockquote"},
    {:p, %{}, ["Right ", {:em, %{}, "after"}, ".\nNormal ", {:strong, %{}, "para"}, " again.\n"]}]}

  test "works with simple user-defined syntax" do
    assert Markright.to_ast(@input, nil, syntax: @simple_syntax) == @output_simple_syntax
  end

  test "treats <br> normally" do
    input = """
    Line one.  
    Line two.
    """
    assert Markright.to_ast(input) == {:article, %{}, [
      {:p, %{}, ["Line one.", {:br, %{}, nil}, "Line two.\n"]}]}
  end

  @tag :skip
  test "treats block <ul> normally" do
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

  @tag :skip
  test "treats inline <ul> normally" do
    input = """
    **Часть 1. Пришествие рядового Разнобердыева**
    - Первый звонок
    - Шестое кольцо
    - Второй завтрак

    Далее.
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

  @tag :skip
  test "treats <h4> normally" do
    input = """
    ### Часть 1. Section

    #### Часть 1.1. Subsection

    - Первый звонок
    - Шестое кольцо
    - Второй завтрак

    Все.
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
