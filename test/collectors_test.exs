defmodule Markright.Collectors.Test do
  use ExUnit.Case
  use Markright.Tester
  doctest Markright.Collectors.OgpTwitter

  @input """
  # Welcome to the real world!

  > Я вам посылку принёс. Только я вам её [не отдам](http://fbi.org), потому что у вас документов нету.
  —⇓Почтальон Печкин⇓

  ![alt text](http://example.com/picture.png)

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

  @output {:article, %{},
            [{:h1, %{}, "Welcome to the real world!"},
             {:blockquote, %{}, [" Я вам посылку принёс. Только я вам её ",
                        {:a, %{href: "http://fbi.org"}, "не отдам"},
                        ", потому что у вас документов нету.\n—",
                        {:span, %{}, "Почтальон Печкин"}]},
             {:p, %{}, [{:img, %{alt: "alt text", src: "http://example.com/picture.png"}, nil}]},
             {:p, %{}, "Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,\nо котором уже рассказывали здесь в 2015 году."},
             {:pre, %{}, [{:code, %{lang: "elixir"}, "defmodule Xml.Namespaces do\n  @var 42\n\n  def method(param \\ 3.14) do\n    if is_nil(param), do: @var, else: @var * param\n  end"}]},
             {:p, %{}, "Сейчас на подходе обновлённая версия, которая умеет играть\nне только отдельные треки, но и целые плейлисты."}]}

  @accumulated [{Sample, [:h1, :blockquote, :img, :pre, :p, :p, :p, :article]},
                {Markright.Collectors.OgpTwitter, [
                  {:meta, %{content: "summary", name: "twitter:card"}, nil},
                  {:meta, %{content: "object", property: "og:type"}, nil},
                  {:meta, %{content: "http://example.com/picture.png", name: "twitter:image:src", property: "og:image"}, nil},
                  {:meta, %{content: "★★★", name: "twitter:site", property: "og:site_name"}, nil},
                  {:meta, %{content: "Welcome to the real world!", name: "twitter:title", property: "og:title"}, nil},
                  {:meta, %{content: "Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,\nо котором уже рассказывали здесь в 2015 году.", name: "twitter:description", property: "og:description"}, nil}]}]

  @html String.trim """
  <meta content=\"summary\" name=\"twitter:card\"/>
  <meta content=\"object\" property=\"og:type\"/>
  <meta content=\"http://example.com/picture.png\" name=\"twitter:image:src\" property=\"og:image\"/>
  <meta content=\"★★★\" name=\"twitter:site\" property=\"og:site_name\"/>
  <meta content=\"Welcome to the real world!\" name=\"twitter:title\" property=\"og:title\"/>
  <meta content=\"Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,\nо котором уже рассказывали здесь в 2015 году.\" name=\"twitter:description\" property=\"og:description\"/>
  """

  test "builds the twitter/ogp card" do
    Code.eval_string """
    defmodule Sample do
      use Markright.Collector, collectors: Markright.Collectors.OgpTwitter

      def on_ast(%Markright.Continuation{ast: {tag, _, _}} = cont), do: tag
    end
    """
    {ast, acc} = Markright.to_ast(@input, Sample)
    assert {ast, acc} == {@output, @accumulated}
    assert XmlBuilder.generate(acc[Markright.Collectors.OgpTwitter]) == @html
  after
    purge Sample
  end

  @input "Hi, #mudasobwa is a tag."
  @output {:article, %{},
              [{:p, %{}, [
                  "Hi, ",
                  {:a, %{class: "tag", href: "/tags/mudasobwa"}, "mudasobwa"},
                  " is a tag."]}]}

  @accumulated [{Sample, []},
                {Markright.Collectors.Tag, {:ul, %{class: "tags"}, [{:li, %{class: "tag"}, "mudasobwa"}]}}]

  test "builds the tags" do
    Code.eval_string """
    defmodule Sample do
      use Markright.Collector, collectors: Markright.Collectors.Tag
    end
    """
    {ast, acc} = Markright.to_ast(@input, Sample)
    assert {ast, acc} == {@output, @accumulated}
  after
    purge Sample
  end

end
