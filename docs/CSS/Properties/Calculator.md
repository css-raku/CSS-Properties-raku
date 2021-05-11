[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties)
 :: [Calculator](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Calculator)

class CSS::Properties::Calculator
---------------------------------

property calculator and measurement tool.

Synopsis
--------

```raku
use CSS::Properties;
use CSS::Properties::Calculator;
my CSS::Properties $css .= new: :style("font:12pt Helvetica;");
my CSS::Properties::Calculator $calc .= new: :$css, :units<mm>, :veiwport-width<250>;
# Converts a value to a numeric quantity;
my Numeric $font-size = $css.measure: :font-size; # get current font size (mm)
$font-size = $css.measure: :font-size<smaller>;   # compute a smaller font
$font-size = $css.measure: :font-size(120%);      # compute a larger font
my $weight = $css.measure: :font-weight;          # get current font weight 100..900
$weight = $css.measure: :font-weight<bold>;       # compute bold font weight
```

Description
-----------

This module supports evaluation of relative CSS quantities that rely on context. Furthermore the `measure` method converts lengths to preferred units (by default `pt`).

Note: [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/Properties), [CSS::Box](https://css-raku.github.io/CSS-Properties-raku/Box) and [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/Font) objects all encapsulate a calculator object which handles `measure` and `calculate` methods.

    my CSS::Properties $css .= new: :style("font:12pt Helvetica;"), :units<mm>, :veiwport-width<250>;
    my Numeric $font-size = $css.measure: :font-size;

### method weigh

```raku
method weigh(
    $_,
    Int $delta = 0
) returns CSS::Properties::Calculator::FontWeight
```

converts a weight name to a three digit number: 100 lightest ... 900 heaviest

