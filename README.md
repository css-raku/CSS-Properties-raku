# perl6-CSS-Declarations
CSS::Declarations is a class for parsing and managing CSS property lists, including parsing, inheritance, default handling and serialization.


## Basic Construction
```
use v6;
use CSS::Declarations::Units;
use CSS::Declarations;

my $style = "color: red";
my $css = CSS::Declarations.new( :$style );

$css.padding = 5pt;  # set padding on all 4 sides
$css.margin = [5pt, 2pt, 5pt, 2pt];
$css.border-color = 'red';

# output the style
say $css.Str;
```

## CSS Property Accessors 

- color values are converted to Color objects
- other values are converted to strings or numeric, as appropriate
- the .key method returns the value type
- box properties are arrays that contain four sides. For example, 'margin' contains 'margin-top', 'margin-right', 'margin-bottom' and 'margin-left';
- there are also some compound properties that may be accessed directly or via a hash; for example, The 'font' accessor returns a hash containing 'font-size', 'font-family', and other font properties.

```
use CSS::Declarations;

my $css = CSS::Declarations.new: :style("color: orange; text-align: CENTER; margin: 2pt; font: 12pt Helvetica");

say $css.color.hex;      # (FF A5 00)
say $css.color.key;      # 'rgb'
say $css.text-align;     # 'center'
say $css.text-align.key; # 'keyw' (keyword)

# access margin-top, directly and through margin container
say $css.margin-top;     # '2'
say $css.margin-top.key; # 'pt'
say $css.margin;         # [2 2 2 2]
say $css.margin[0];      # '2'
say $css.margin[0].key;  # 'pt'

# access font-family directly and through font container
say $css.font-family;       # 'Helvetica'
say $css.font-family.key;   # 'ident'
say $css.font<font-family>; # 'Helvetica;
```

The simplest ways of setting a property is to assign a string value.  The value will be parsed as CSS. This works for both simple and container properties. Unit values are also recognized.

```
use CSS::Declarations::Units;
my $css = (require CSS::Declarations).new;

# assign to container
$css.font = "14pt Helvetica";

# assign to simple properties
$css.font-weight = 'bold'; # string
##$css.line-height = 16pt;   # unit value

say ~$css; # font:bold 14pt/16pt Helvetica;
```

## CSS Modules

## Conformance Levels

Processing defaults to CSS level 3 (class CSS::Module::CSS3). This can be configured via the :module option:

```
use CSS::Declarations;
use CSS::Module::CSS1;
use CSS::Module::CSS21;

my $style = 'color: red; azimuth: left';

my $module = CSS::Module::CSS1.module;
my $css1 = CSS::Declarations.new( :$style, :$module);
## warnings: dropping unknown property: azimuth

$module = CSS::Module::CSS21.module;
my $css21 = CSS::Declarations.new( :$style, :$module);
## (no warnings)
```

### '@font-face' Declarations

`@font-face` is a sub-module of `CSS3`. To process a set of `@font-face` declarations, such as:

```
@font-face {
    font-family: myFirstFont;
    src: url(sansation_light.woff);
}
```

```
use CSS::Declarations;
use CSS::Module::CSS3;

my $style = "font-family: myFirstFont; src: url(sansation_light.woff)";
my $module = CSS::Module::CSS3.module.sub-module<@font-face>;
my $font-face-css = CSS::Declarations.new( :$style, :$module);
```

## Default values

Most properties have a default value. If a property is reset to its default value it will be omitted from stringification:

    my $css = (require CSS::Declarations).new;
    say $css.background-image; # none
    $css.background-image = 'url(camellia.png)';
    say ~$css; # "background-image: url(camellia.png);"
    $css.background-image = $css.info("background-image").default;
    say ~$css; # ""

## Inheritance

A child class can inherit from one or more parent classes. This follows CSS standards:

- Note all properties are inherited by default; for example `color` is inherited, but `margin` is not.

- the `inherit` keyword can be used in the child property to ensure inheritance.

- `initial` will reset the child property to the default value

- the `!important` modifier can be used in parent properties to force the parent value to override the child. The property becomes 'important' in the child and will be passed on to any CSS::Declarations objects that inherit from it.

```
my $parent-css = CSS::Declarations.new: :style("margin-top:5pt; margin-left: 15pt; color:rgb(0,0,255) !important");

my $css = CSS::Declarations.new: :style("margin-top:25pt; margin-right: initial; margin-left: inherit; color:purple"), :inherit($parent-css);

say $parent-css.important("color");
## True
say $css.handling("margin-left");
## inherit
```

## Serialization

The `.write` or `.Str` methods can be used to produce CSS. Properties are optimized and normalized:

- properties with default values are omitted

- simple properties are consolidated to containers (e.g. `font-family` to `font`).

- rgb masks are translated to color-names, if possible

```
use CSS::Declarations;
my $css = CSS::Declarations.new( :style("border-style: groove; border-width: 2pt 2pt; color: rgb(255,0,0);") );
say $css.write;  # "border: 2pt; color: red;"
```

Notice that:

- `border-style` was omitted because it has the default value

- `border-width` has been consolidated to the `border` container property. This was possible
because all four borders had the common value `2pt`

- `color` has been translated from a color mask to a color

`$.write` Options include:

- `:!optimize` - turn off optimization. Don't, combine simple properties into compound properties (`border-style`, `border-width`, ... => `border`), or combine edges (`margin-top`, `margin-left`, ... => `margin`).

- `:!terse` - enable multi-line output

- `:!color-names` - don't translate RGB values to color-names

## Property Meta-data

The `info` method gives property specific meta-data, on all simple of compound properties. It returns an object of type CSS::Declarations::Property:

```
use CSS::Declarations;
my $css = CSS::Declarations.new;
my $margin-info = $css.info("margin");
say $margin-info.synopsis; # <margin-width>{1,4}
say $margin-info.edges;    # [margin-top margin-right margin-bottom margin-left]
say $margin-info.inherit;  # True (property is inherited)
```

## Data Introspection

The `properties` method, gives a list of current properties. Only simple properties
are returned. E.g. `font-family` is, if it has a value; but `font` isn't.

```
use CSS::Declarations;

my $style = "margin-top: 10%; margin-right: 5mm; margin-bottom: auto";
my $css = CSS::Declarations.new: :$style;

for $css.properties -> $prop {
    my $val = $css."$prop"();
    say "$prop: $val {$val.key}";
}

```
Gives:
```
margin-top: 10 percent
margin-bottom: auto keyw
margin-right: 5 mm
```

## Length Units

CSS::Declaration::Units is a convenience module that provides some simple postfix length unit definitions, plus overriding of the '+' and '-'
operators. These are understood by the CSS::Declarations class.

The '+' and '-' operators convert to the left-hand operand's units.

```
use CSS::Declarations::Units;
my $css = (require CSS::Declarations).new: :margin[5pt, 10px, .1in, 2mm];

# display margins in millimeters
say "%.2f mm".sprintf(0mm + $_) for $css.margin.list;
```
