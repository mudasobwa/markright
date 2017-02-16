# Markright

[![Build Status](https://travis-ci.org/mudasobwa/markright.svg?branch=master)](https://travis-ci.org/mudasobwa/markright) **The extended, streaming, configurable markdown-like syntax parser, that produces an AST.**

Out of the box is supports the full set of `markdown`, plus some extensions.
The user of this library might easily extend the functionality with her own
markup definition and a bit of elixir code to handle parsing.

There is no one single call to `Regex` used. The whole parsing is done solely
on pattern matching the input binary.

The AST produced is understandable by [`XmlBuilder`](https://github.com/joshnuss/xml_builder).

There are many callbacks available to transform the resulting AST. See below.

## Is it of any good?

It is an incredible piece of handsome lovely software. Sure, it is.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `markright` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:markright, "~> 0.2.0"}]
end
```

## Basic usage

```elixir
    @input ~s"""
    If [available in Hex](https://hex.pm/docs/publish), the package can be installed
    by adding `markright` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:markright, "~> 0.2.0"}]
    end
    ```

    ## Basic Usage
    Blah...
    """

    assert(
      Markright.to_ast(@input) ==
        {:article, %{},
           [{:p, %{}, [
              "If ", {:a, %{href: "https://hex.pm/docs/publish"}, "available in Hex"},
              ", the package can be installed\nby adding ", {:code, %{}, "markright"},
              " to your list of dependencies in ", {:code, %{}, "mix.exs"}, ":"]},
            {:pre, %{},
              [{:code, %{lang: "elixir"},
              "def deps do\n  [{:markright, \"~> 0.1.0\"}]\nend"}]},
            {:p, %{}, [{:h2, %{}, "Basic Usage"}]}, {:p, %{}, "Blah...\n"}]}
    )
```

Yes, for unknown reason headers are yet parsed inside `:p` tag, no idea why.
Suggestions (specifically having the form of _pull requests_) are very welcome.

## HTML generation

```elixir
iex> "Hello, *[address]Aleksei*!"
...> |> Markright.to_ast
...> |> XmlBuilder.generate
"<article>
\t<p>
\t\tHello,
\t\t<strong class=\"address\">Aleksei</strong>
\t\t!
\t</p>
</article>"
```

## Power tools

### Callbacks

One might provide a callback to the call to `to_ast/3`. It will be not only
called back on any AST node found (do not expect them to be called in the
natural order, though,) but it _allows to change the AST on the fly_. Just
return a `%Markright.Continuation` object from the callback, and you are done
(see `markright_test.exs` for inspiration):

```elixir
fun = fn
  %Markright.Continuation{ast: {:p, %{}, text}} = cont ->
    IO.puts "Currently dealing with `:p` node"
    %Markright.Continuation{cont | ast: {:div, %{}, text}}
  cont -> cont
end
assert Markright.to_ast(@input, fun) == @output
```

### Make fancy links inside blockquotes

When a last blockquote’s element is a link, make it to show the favicon,
and make the blockquote itself to have `cite` attribute (in fact, this particular
transform is already done in `Markright.Finalizers.Blockquote` finalizer, but if
it were not, this is how it could be implemented internally):

```elixir
bq_patch = fn
  {:blockquote, bq_attrs, list} when is_list(list) ->
    case :lists.reverse(list) do
      [{:a, %{href: href} = attrs, text} | t] ->
        img = with [capture] <- Regex.run(~r|\Ahttps?://[^/]+|, href) do
          {:img,
              %{alt: "favicon",
                src: capture <> "/favicon.png",
                style: "height:16px;margin-bottom:-2px;"},
              nil}
        end
        patched = :lists.reverse([{:br, %{}, nil}, "— ", img, " ", {:a, attrs, text}])
        {:blockquote, Map.put(bq_attrs, :cite, href), :lists.reverse(patched ++ t)}
      _ -> {:blockquote, bq_attrs, list}
    end
  other -> other
end
fun = fn %Markright.Continuation{ast: ast} = cont ->
  %Markright.Continuation{cont | ast: bq_patch.(ast)}
end
```

### Custom classes

All the “grip” elements (like `*strong*` or `~strike~`) have an option to specify
a class:

```elixir
iex> Markright.to_ast "Hello, *[address]Aleksei*!"
{:article, %{},
  [{:p, %{}, ["Hello, ", {:strong, %{class: "address"}, "Aleksei"}, "!"]}]}
```

The above is particularly helpful when writing a rich blog posts over, say,
bootstrap css (or any other css, that provides cool flashes etc.)

### Custom syntax

To add a new syntax is as easy as to put a new value into `config`:

```elixir
config :markright, syntax: [
  grip: [
    sup: "^^"
  ]
]
```

### Ninja handling: collectors

Collectors play the role of accumulators, used for accumulating some data
during the parsing stage. The good example of it would be
`Markright.Collectors.OgpTwitter` collector, that is used to build the
twitter/ogp card to embed into head section of the resulting html.

```elixir
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
```

Voilà—you have this grip on hand:

```elixir
iex> Markright.to_ast "Hello, ^^Aleksei^^!"
{:article, %{},
  [{:p, %{}, ["Hello, ", {:sup, %{}, "Aleksei"}, "!"]}]}
```

### Development

The extensions to syntax are not supposed to be merged into trunk. I am thinking
about creating a welcome plugin-like infrastructure. Suggestions are very welcome.

## Documentation

Visit [HexDocs](https://hexdocs.pm). Our docs can
be found at [https://hexdocs.pm/markright](https://hexdocs.pm/markright).
