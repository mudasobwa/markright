defmodule Markright.Parsers.Pre.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Pre

  @input ~S"""
  Hello world.

  ```ruby
  def method(*args, **args)
    puts "method #{__callee__} called"
  end
  ```

  Right after.
  Normal *para* again.
  """

  @output {:article, %{}, [
    {:p, %{}, "Hello world."},
     {:pre, %{},
      [{:code, %{lang: "ruby"},
       "def method(*args, **args)\n  puts \"method \#{__callee__} called\"\nend"}]},
     {:p, %{},
      ["Right after.\nNormal ", {:strong, %{}, "para"}, " again.\n"]}]}

  test "understands codeblock in the markright" do
    assert Markright.to_ast(@input) == @output
  end

  @output {:article, %{}, [
    {:div, %{}, "Hello world."},
     {:pre, %{},
      [{:code, %{lang: "ruby"},
       "def method(*args, **args)\n  puts \"method \#{__callee__} called\"\nend"}]},
     {:div, %{},
      ["Right after.\nNormal ", {:strong, %{}, "para"}, " again.\n"]}]}

  test "makes changes in the callbacks" do
    fun1 = fn
      %Markright.Continuation{ast: {:p, %{}, text}} = cont ->
        %Markright.Continuation{cont | ast: {:div, %{}, text}}
      cont -> cont
    end
    assert Markright.to_ast(@input, fun1) == @output

    fun2 = fn
      {:p, %{}, text}, tail ->
        %Markright.Continuation{ast: {:div, %{}, text}, tail: tail}
      ast, tail ->
        %Markright.Continuation{ast: ast, tail: tail}
    end
    assert Markright.to_ast(@input, fun2) == @output
  end

end
