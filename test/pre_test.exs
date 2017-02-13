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
       "\ndef method(*args, **args)\n  puts \"method \#{__callee__} called\"\nend"}]},
     {:p, %{},
      ["Right after.\nNormal ", {:strong, %{}, "para"}, " again.\n"]}]}

  test "understands codeblock in the markright" do
    assert Markright.to_ast(@input) == @output
  end

end
