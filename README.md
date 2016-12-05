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
- some properties are containers only. For example, 'margin' is a container property for 'margin-top', 'margin-left', e.g.
- also, for example, 'font' is a hash container for 'font-size', 'font-family', etc

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

# access font-family directly and through container
say $css.font-family;       # 'Helvetica'
say $css.font-family.key;   # 'indent'
say $css.font<font-family>; # 'Helvetica;
```

The simplest ways of setting a property is to assign a string value.  The value will be parsed as CSS. This works for both simple and container properties. Unit values are also recognized.

````
my $css = (require CSS::Declarations).new;

# assign to container
$css.font = "14pt Helvetica";

# assign to simple properties
$css.font-weight = 'bold'; # assign string
$css.line-height = 16pt;   # assign unit value

say ~$css; # font:bold 14pt/16pt Helvetica;
````

## CSS Modules and Levels

Processing defaults to CSS level 3 (class CSS::Module::CSS3). This can be altered via the :module option:

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

`@font-face` is a sub-module of `CSS3`. To process a rule-set, such as:

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

    ```
    my $css = (require CSS::Declarations).new;
    say $css.background-image; # none
    $css.background-image = 'url(camellia.png)';
    say ~$css; # "background-image: url(camellia.png);"
    $css.background-image = $css.info("background-image").default;
    say ~$css; # ""
    ```

## Inheritance

A child class can inherit from one or more parent classes. This is applied in a CSS conformant manner:

- heritability is property specific. For example `color` is inherited, but `margin` is not.

- the `inherit` keyword can be used in the child property to force inheritance.

- the `!important` modifier can be used in parent properties to force inheritance to the child. The property remains 'important' in the child and will be passed on to any CSS::Declarations objects that inherit from it.

```
my $parent-css = CSS::Declarations.new: :style("margin-top:5pt; margin-left: 15pt; color:rgb(0,0,255) !important");

my $css = CSS::Declarations.new: :style("margin-top:25pt; margin-right: initial; margin-left: inherit; color:purple"), :inherit($parent-css) );

say $parent-css.important("color");
## True
say $css.handling("margin-left");
## inherit
```

## Serialization

Properties are optimized and normalized during serialization, including:

- omission of properties with default values, and

- consolidation of compound properties. E.g.:

```
use CSS::Declarations;
my $css = CSS::Declarations.new( :style("border-style: groove; border-width: 2pt 2pt; color: rgb(255,0,0);") );
say $css.write;  # "border: 2pt; color: red;"
```

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

The `properties` method, gives a list of current property names.

The attributes of a parsed quantity can be accessed via the `.key` method:

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
