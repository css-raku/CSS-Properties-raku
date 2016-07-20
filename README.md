# perl6-CSS-Declarations
CSS rul-set representations, including inheritance, default handling and serialization

## Basic Construction
```
use v6;
use CSS::Declarations::Units;
use CSS::Declarations::Element;

my $style = "color: red";
my $css = CSS::Declarations.new( :$style );

$css.padding = 5pt;  # set padding on all 4 sides
$css.margin = [5pt, 2pt, 5pt, 2pt];

# output the style
say $css.write;
```

## Parsing of CSS style rules 

```
use CSS::Declarations;

my $css = CSS::Declarations.new: :style("color: orange; text-align: center; margin: 2pt; border-width: 1px 2px 3pt");

say $css.color;     # [255, 165, 0];
say $css.color.key; # 'rgb';
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

### '@font-face' Declarations

`@font-face` is a sub-module of `CSS3`. To process a ruleset, such as:

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

## Inheritance

```
my $parent-css = CSS::Declarations.new: :style("margin-top:5pt; margin-left: 15pt; color:rgb(0,0,255) !important");

my $css = CSS::Declarations.new( :style("margin-top:25pt; margin-right: initial; margin-left: inherit; color:purple"), :inherit($parent-css) );

say $parent-css.important("color");
## True
say $css.handling("margin-left");
## inherit
```

Parent styles can be inherited one at a time, either using by the `:inherit` construction option, or the `inherit` method. Inheritance aims to be CSS conformant, including:

- setting property initial values

- `initial` and `inherit` keywords, in the child class

- `!important` properties in the parent class

- property specific inheritance rules; e.g. as defined in https://www.w3.org/TR/CSS21/propidx.html#q24.0

## Serialization

Properties are optimized and normalized during serialization. E.g.:

```
use CSS::Declarations;
$css = CSS::Declarations.new( :style("border-style: groove; border-width: 2pt; color: rgb(255,0,0);") );
say $css.write;  # "border: 2pt; color: red;"
```

`$.write` Options include:

- `:!optimize` - turn off optmization. Don't, combine simple properties into compound properties (`border-style`, `border-width`, ... => `border`), or combine edges (`margin-top`, `margin-left`, ... => `margin`).

- `:!terse` - enable multi-line output

- `:!color-names` - don't translate RGB values to color-names

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

Note that properties are broken down into simple components, For example `margin` is broken down into `margin-top`, `margin-right`, `margin-bottom`, `margin-left`. It is only reassembled during serialization.

The `info` method gives property specific metadata, on all simple of compound properties. It returns an object of type CSS::Declarations::Property:

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

