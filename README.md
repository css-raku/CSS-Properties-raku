# perl6-CSS-Declarations
CSS Property set representations, including box model, inheritance and default handling

## Basic Construction
```
use v6;
use CSS::Declarations::Units;
use CSS::Declarations::Element;

my $css = CSS::Declarations.new;

$css.padding = 5pt;  # set padding on all 4 sides
$css.border-width = 3pt;
$css.margin = [5pt, 2pt, 5pt, 2pt];

# create an element, giving the vertices of the content-box
my $element = CSS::Declarations::Element.new( :top(80pt), :left(0pt), :bottom(0pt), :right(50pt), :$css, :units(in));

# display margin box (in inches)
say $element.margin;
```

## Parsing of style rules 

```
use v6;
use CSS::Declarations;
use Test;

my $css = CSS::Declarations.new: :style("color: orange; text-align: center; margin: 2pt; border-width: 1px 2px 3pt");

say $css.color;     # [255, 165, 0];
say $css.color.key; # 'rgb';
```

## Inheritance

```
my $parent-css = CSS::Declarations.new: :style("margin-top:5pt; margin-right: 10pt; margin-left: 15pt; margin-bottom: 20pt; color:rgb(0,0,255) !important");

my $css = CSS::Declarations.new( :style("margin-top:25pt; margin-right: initial; margin-left: inherit; color:purple"), :inherit($parent-css) );
```

This aims to be CSS conformant, including:
-- property default values
-- `initial` and `inherit` keywords, in the child class
-- `!important` properties in the parent class
-- property specific inheritance rules; e.g. as defined in https://www.w3.org/TR/CSS21/propidx.html#q24.0

