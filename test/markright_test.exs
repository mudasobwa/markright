defmodule Markright.Test do
  use ExUnit.Case
  doctest Markright

  @input_text ~S"""
  **Опыт использования пространств имён в клиентском XHTML**

  _Текст Ростислава Чебыкина._

  > Я вам посылку принёс. Только я вам её [не отдам](http://fbi.org), потому что у вас документов нету.
  > —⇓Почтальон Печкин⇓

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
  \t</blockquote>
  \t<blockquote>
  \t\t —
  \t\t<span>Почтальон Печкин</span>
  \t</blockquote>
  \t<p>Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  \tо котором уже рассказывали здесь в 2015 году.</p>
  \t<pre>
  \t\t<code lang=\"elixir\">defmodule Xml.Namespaces do
  \t  @var 42
  \t  def method(param \\\\ 3.14) do
  \t    if is_nil(param), do: @var, else: @var * param
  \t  end</code>
  \t</pre>
  \t<p>Сейчас на подходе обновлённая версия, которая умеет играть
  \tне только отдельные треки, но и целые плейлисты.</p>
  </article>
  """

  test "generates XML from parsed markright" do
    assert(@input_text
           |> Markright.to_ast
           # |> IO.inspect
           |> XmlBuilder.generate == String.trim(@output_text))
  end

  @tag :skip
  test "properly handles nested blockquotes" do
    assert(@input_blockquote
           |> Markright.to_ast ==
     {:article, %{}, [{:blockquote, %{}, [" Blockquote!", " This is level 2."]}]})
  end

  @tag :skip
  test "handles unterminated symbols properly" do
    assert("Unterminated *asterisk"
           |> Markright.to_ast ==
      {:article, %{}, [{:p, %{}, ["Unterminated asterisk"]}]})
  end

end
