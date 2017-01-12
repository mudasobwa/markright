defmodule Markright.Test do
  use ExUnit.Case
  doctest Markright

  @input_text ~S"""
  **Опыт использования пространств имён в клиентском XHTML**

  _Текст Ростислава Чебыкина._

  > Я вам посылку принёс. Только я вам её [не отдам](http://fbi.org), потому что у вас документов нету.
  —⇓Почтальон Печкин⇓

  Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  о котором уже рассказывали здесь в 2015 году.

  ```elixir
  defmodule Xml.Namespaces do
    @var 42

    def method(param \\ 3.14) do
      if is_nil(param), do: @var, else: @var * param
    end
  ```

  Сейчас на подходе обновлённая версия, которая умеет играть
  не только отдельные треки, но и целые плейлисты.
  """

  @input_blockquote "> Blockquotes!\n> This is level 2."

  @output_text ~s"""
  <article>
  \t<p>
  \t\t<b>Опыт использования пространств имён в клиентском XHTML</b>
  \t</p>
  \t<p>
  \t\t<em>Текст Ростислава Чебыкина.</em>
  \t</p>
  \t<blockquote>
  \t\t Я вам посылку принёс. Только я вам её\s
  \t\t<a href=\"http://fbi.org\">не отдам</a>
  \t\t, потому что у вас документов нету.
  —
  \t\t<span>Почтальон Печкин</span>
  \t</blockquote>
  \t<p>Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  о котором уже рассказывали здесь в 2015 году.</p>
  \t<pre>
  \t\t<code lang=\"elixir\">defmodule Xml.Namespaces do
    @var 42

    def method(param \\\\ 3.14) do
      if is_nil(param), do: @var, else: @var * param
    end</code>
  \t</pre>
  \t<p>Сейчас на подходе обновлённая версия, которая умеет играть
  не только отдельные треки, но и целые плейлисты.
  </p>
  </article>
  """

  test "generates XML from parsed markright" do
    assert(@input_text
           |> Markright.to_ast(fn e -> IO.puts "★☆★ #{inspect e}" end)
           # |> IO.inspect
           |> XmlBuilder.generate == String.trim(@output_text))
  end

  test "properly handles nested blockquotes" do
    assert(@input_blockquote
           |> Markright.to_ast ==
     {:article, %{}, [{:blockquote, %{}, " Blockquotes!  This is level 2."}]})
  end

  test "handles unterminated symbols properly" do
    assert("Unterminated *asterisk"
           |> Markright.to_ast ==
      {:article, %{}, [{:p, %{}, ["Unterminated ", {:strong, %{}, "asterisk"}]}]})
  end

  @readme ~s"""
  If [available in Hex](https://hex.pm/docs/publish), the package can be installed
  by adding `markright` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:markright, "~> 0.1.0"}]
  end
  ```

  ## Basic Usage
  """

  test "understands our own README" do
    assert(Markright.to_ast(@readme) ==
      {:article, %{}, [
        {:p, %{}, [
          "If ",
          {:a, %{href: "https://hex.pm/docs/publish"},
          "available in Hex"},
          ", the package can be installed\nby adding ",
          {:code, %{}, "markright"},
          " to your list of dependencies in ",
          {:code, %{}, "mix.exs"},
          ":"]},
        {:pre, %{}, [
          {:code, %{lang: "elixir"},
            "def deps do\n  [{:markright, \"~> 0.1.0\"}]\nend"}]},
        {:p, %{}, "## Basic Usage\n"}]}
    )
  end

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


  @badge_url "http://mel.fm/2016/05/22/plural"


end
