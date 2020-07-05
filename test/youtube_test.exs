defmodule Markright.Parsers.Youtube.Test do
  @moduledoc false
  use ExUnit.Case
  doctest Markright.Parsers.Youtube

  @input """
  Leonard Cohen :: Miracle to come

  ✇http://www.youtube.com/embed/noQcPIeW6tE
    
  Baby, I’ve been waiting
  """

  # <iframe width="560"
  #         height="315"
  #         src="https://www.youtube.com/embed/BvCBTpnlqs8"
  #         frameborder="0"
  #         allowfullscreen></iframe>

  @output {:article, %{},
           [
             {:p, %{}, "Leonard Cohen :: Miracle to come"},
             {:p, %{},
              [
                {:iframe,
                 %{
                   allowfullscreen: nil,
                   frameborder: 0,
                   height: 315,
                   src: "http://www.youtube.com/embed/noQcPIeW6tE",
                   width: 560
                 }, "http://www.youtube.com/embed/noQcPIeW6tE"},
                "\n",
                {:br, %{}, nil},
                "Baby, I’ve been waiting\n"
              ]}
           ]}

  test "parses youtube image tag" do
    assert @input
           |> Markright.to_ast() == @output
  end
end
