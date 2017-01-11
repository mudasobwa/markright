defmodule Markright.Parsers.Code.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Code

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
    assert (@input
            |> Markright.to_ast(fn cont -> IO.puts "\n\n★[TEST]★ #{inspect(cont)}\n\n" end)) == @output
  end
end
