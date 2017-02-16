  defmodule Markright.Parsers.Lj do
    @moduledoc ~S"""
    Makes all the mailto:who@where.domain texts to be links.

    ## Examples

        iex> input = "✎mudasobwa wrote"
        iex> Markright.Parsers.Lj.to_ast(input)
        %Markright.Continuation{
          ast: {:span, %{class: "ljuser i-ljuser i-ljuser-type-P"},
            [{:a, %{class: "i-ljuser-profile",
                    href: "http://mudasobwa.livejournal.com/profile",
                    target: "_self"},
                [{:img, %{class: "i-ljuser-userhead ContextualPopup",
                          src: "http://l-stat.livejournal.net/img/userinfo.gif?v=17080?v=145"}, nil}]},
             {:a, %{class: "i-ljuser-username",
                    href: "http://mudasobwa.livejournal.com/",
                    target: "_self"}, [{:strong, %{}, "mudasobwa"}]}]},
          tail: " wrote"}
    """

    use Markright.Helpers.Magnet

    def to_ast(input, fun \\ nil, opts \\ %{})
      when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

      %Markright.Continuation{ast: <<@magnet :: binary, username :: binary>>} = cont = astify(input)
      cont = %Markright.Continuation{cont | ast:
        [
          {:a, %{href: "http://#{username}.livejournal.com/profile",
                 target: "_self",
                 class: "i-ljuser-profile"},
               [{:img, %{class: "i-ljuser-userhead ContextualPopup",
                         src: "http://l-stat.livejournal.net/img/userinfo.gif?v=17080?v=145"}, nil}]},
          {:a, %{class: "i-ljuser-username",
                 href: "http://#{username}.livejournal.com/",
                 target: "_self"}, [{:strong, %{}, username}]}
        ]}
      Markright.Utils.continuation(:continuation, cont, {:span, %{class: "ljuser i-ljuser i-ljuser-type-P"}, fun})
    end
  end
