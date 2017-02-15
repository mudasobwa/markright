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
             {:p, %{}, ["\n> Я вам посылку принёс. Только я вам её ",
                        {:a, %{href: "http://fbi.org"}, "не отдам"},
                        ", потому что у вас документов нету.\n—",
                        {:span, %{}, "Почтальон Печкин"}]},
             {:p, %{}, [{:img, %{alt: "alt text", src: "http://example.com/picture.png"}, nil}]},
             {:p, %{}, "Мы вместе с Денисом Лесновым разрабатываем аудиопроигрыватель для сайта,\nо котором уже рассказывали здесь в 2015 году."},
             {:pre, %{}, [{:code, %{lang: "elixir"}, "\ndefmodule Xml.Namespaces do\n  @var 42\n\n  def method(param \\ 3.14) do\n    if is_nil(param), do: @var, else: @var * param\n  end"}]},
             {:p, %{}, "Сейчас на подходе обновлённая версия, которая умеет играть\nне только отдельные треки, но и целые плейлисты."}]}

  @accumulated [{Sample, [:h1, :a, :img, :pre, :p, :p, :p, :p, :article]},
                {Markright.Collectors.OgpTwitter, [:boom, :boom, :boom, :boom, :boom, :boom, :boom, :boom, :boom]}]


  test "builds the twitter/ogp card" do
    Code.eval_string """
    defmodule Sample do
      use Markright.Collector, collectors: Markright.Collectors.OgpTwitter

      def on_ast(%Markright.Continuation{ast: {tag, _, _}} = cont), do: tag
    end
    """
    assert Markright.to_ast(@input, Sample) == {@output, @accumulated}
  after
    purge Sample
  end

  @badge_url "http://mel.fm/2016/05/22/plural"


end
