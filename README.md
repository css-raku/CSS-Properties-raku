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

## Parsing of CSS style rules 

```
use CSS::Declarations;

my $css = CSS::Declarations.new: :style("color: orange; text-align: center; margin: 2pt; border-width: 1px 2px 3pt");

say $css.color;     # [255, 165, 0];
say $css.color.key; # 'rgb';
```

## Property Metadata

The `.property` method returns a `CSS::Declarations::Property` object for property introspection.
```
use CSS::Declarations;
my $css = CSS::Declarations.new;
my $prop = $css.property("background-image");
say "name:     {$prop.name}";
sys "synopsis: {$prop.synopsis}";
say "default:  {$prop.default}";
say "inherit:  {$prop.inherit ?? 'Y' !! 'N'}";
```

## CSS Modules and Levels

Processing defaults to CSS level 3. This can be altered via the :module option:

```
use CSS::Declarations;
use CSS::Module::CSS1;
use CSS::Module::CSS21;

my $style = 'color: red; azimuth: left';

my $module = CSS::Module::CSS1.module;
my $css1 = CSS::Declarations.new( :$style, :$module);
.say for $css1.warnings;
## "dropping unknown property: azimuth"

$module = CSS::Module::CSS21.module;
my $css21 = CSS::Declarations.new( :$style, :$module);
.say for $css21.warnings "";
## (no warnings)
```

## Inheritance

```
my $parent-css = CSS::Declarations.new: :style("margin-top:5pt; margin-left: 15pt; color:rgb(0,0,255) !important");

my $css = CSS::Declarations.new( :style("margin-top:25pt; margin-right: initial; margin-left: inherit; color:purple"), :inherit($parent-css) );

say $parent-css.important("color");
## True
say $css.handling("margin-left");
## inherit
```

Parent styles can be inherited one at a time, eithing using by the `:inherit` construction option, or the `inherit` method. Inheritance aims to be CSS conformant, including:

- setting property initial values

- `initial` and `inherit` keywords, in the child class

- `!important` properties in the parent class

- property specific inheritance rules; e.g. as defined in https://www.w3.org/TR/CSS21/propidx.html#q24.0

## Serialization

```
use CSS::Declarations;
$css = CSS::Declarations.new( :style("border-style: groove; border-width: 2pt; margin: inherit") );
say $css.write;  # "border: groove 2pt; margin: inherit;"
```

## CSS Elements & Units

`CSS::Declaration::Element` is a base class for computing sizes of CSS elements, based on the CSS Box module.

Basically an element consists of a core content box, surrounded by
concentric `padding`, `border` and `margin` boxes.

```
use CSS::Declarations;
use CSS::Declarations::Units;
use CSS::Declarations::Element;

my $css = CSS::Declarations.new: :style("padding:5pt; border:3pt; margin: 1pt 2pt 3pt 4pt");

# style a content box between [0, 0] and [50, 80]
# rendering units are 'pt'

my $top    = 80pt;
my $right  = 50pt;
my $bottom = 0pt;
my $left   = 0pt;
my $units  = pt;

my $element = CSS::Declarations::Element.new( :$top, :$left, :$bottom, :$right, :$css, :$units);

# determine coordinates of padding and margin boxes (pt)
say $element.padding; # [85 55 -5 -5]
say $element.margin;  # [89 60 -11 -12]

# also show padding coordinates in pixels
$element.units = Units::px;
say $element.padding; # [63.75 41.25 -3.75 -3.75]
```



