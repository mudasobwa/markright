defmodule Markright.Test do
  use ExUnit.Case
  doctest Markright

  @input_text ~S"""
  **Опыт использования пространств имён в клиентском XHTML**

  _Текст Ростислава Чебыкина._

  > Я вам посылку принёс. Только я вам её не отдам, потому что у вас документов нету.
  > —⇓Почтальон Печкин⇓

  Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  о котором уже рассказывали здесь в 2015 году.
  Сейчас на подходе обновлённая версия, которая умеет играть
  не только отдельные треки, но и целые плейлисты.
  """

  @output_text ~s"""
  <p>
  \t<b>Опыт использования пространств имён в клиентском XHTML</b>
  </p>
  <p>
  \t<em>Текст Ростислава Чебыкина.</em>\n</p>
  <blockquote> Я вам посылку принёс. Только я вам её не отдам, потому что у вас документов нету.</blockquote>
  <blockquote>
  \t —
  \t<span>Почтальон Печкин</span>
  </blockquote>
  <p>Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,
  о котором уже рассказывали здесь в 2015 году.
  Сейчас на подходе обновлённая версия, которая умеет играть
  не только отдельные треки, но и целые плейлисты.</p>
  """

  @input_code ~S"""
  Hello world.

  ```ruby
  def method(*args, **args)
    puts "method #{__callee__} called"
  end
  ```

  Right after.
  Normal *para* again.
  """

  @output_code [
    {:p, %{}, "Hello world."},
     {:pre, %{},
      {:code, %{lang: "ruby"},
       "def method(*args, **args)\n  puts \"method \#{__callee__} called\"\nend"}},
     {:p, %{},
      ["Right after.\nNormal ", {:strong, %{}, "para"}, " again."]}]

  test "generates XML from parsed markright" do
    assert (@input_text
            |> Markright.to_ast
            |> IO.inspect
            |> XmlBuilder.generate) == String.trim(@output_text)
  end

  test "understands codeblocks in the markright" do
    assert (@input_code
            |> Markright.to_ast
            |> IO.inspect) == @output_code
  end
end
