defmodule Markright.Parsers.Lj.Test do
  use ExUnit.Case
  doctest Markright.Parsers.Lj

  @input ~S"""
  Hi, ✎mudasobwa wrote [Lingua latina](http://mudasobwa.livejournal.com/544872.html).
  """

  @output {:article, %{},
           [
             {:p, %{},
              [
                "Hi, ",
                {:span, %{class: "ljuser i-ljuser i-ljuser-type-P"},
                 [
                   {:a,
                    %{
                      class: "i-ljuser-profile",
                      href: "http://mudasobwa.livejournal.com/profile",
                      target: "_self"
                    },
                    [
                      {:img,
                       %{
                         class: "i-ljuser-userhead ContextualPopup",
                         src: "http://l-stat.livejournal.net/img/userinfo.gif?v=17080?v=145"
                       }, nil}
                    ]},
                   {:a,
                    %{
                      class: "i-ljuser-username",
                      href: "http://mudasobwa.livejournal.com/",
                      target: "_self"
                    }, [{:strong, %{}, "mudasobwa"}]}
                 ]},
                " wrote ",
                {:a, %{href: "http://mudasobwa.livejournal.com/544872.html"}, "Lingua latina"},
                "."
              ]}
           ]}

  @output_xml ~s"""
  <article>
  \t<p>
  \t\tHi, 
  \t\t<span class=\"ljuser i-ljuser i-ljuser-type-P\">
  \t\t\t<a class=\"i-ljuser-profile\" href=\"http://mudasobwa.livejournal.com/profile\" target=\"_self\">
  \t\t\t\t<img class=\"i-ljuser-userhead ContextualPopup\" src=\"http://l-stat.livejournal.net/img/userinfo.gif?v=17080?v=145\"/>
  \t\t\t</a>
  \t\t\t<a class=\"i-ljuser-username\" href=\"http://mudasobwa.livejournal.com/\" target=\"_self\">
  \t\t\t\t<strong>mudasobwa</strong>
  \t\t\t</a>
  \t\t</span>
  \t\t wrote 
  \t\t<a href=\"http://mudasobwa.livejournal.com/544872.html\">Lingua latina</a>
  \t\t.
  \t</p>
  </article>
  """

  test "parses livejournal user name" do
    assert @input
           |> Markright.to_ast() == @output
  end

  test "generates html for livejournal user name" do
    assert @input
           |> Markright.to_ast()
           |> XmlBuilder.generate(format: :none) == String.replace(@output_xml, ~r/\n|\t/, "")
  end
end
