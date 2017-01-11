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

end
