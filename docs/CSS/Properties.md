[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties)

class CSS::Properties
---------------------

management class for a set of CSS Properties

Synopsis
--------

```raku
use CSS::Units :pt;
use CSS::Properties;

my CSS::Properties() $css = "color:red !important; padding: 1pt";
say $css.important("color"); # True
$css.border-color = 'red';

$css.margin = [5pt, 2pt, 5pt, 2pt];
$css.margin = 5pt;  # set margin on all 4 sides

# set text alignment
$css.text-align = 'right';

say ~$css; # border-color:red; color:red!important; margin:5pt; padding:1pt; text-align:right;
```

Description
-----------

This class manages a list of properties. These are typically parsed from the body of a CSS rule-set or from an inline `style` tag.

CSS Property Accessors
----------------------

CSS Properties provides `rw` accessors for all standard CSS3 properties.

  * color values are converted to Color objects

  * other values are converted to strings or numeric, as appropriate

  * the .type method returns additional type information

  * box properties are arrays that contain four sides. For example, 'margin' contains 'margin-top', 'margin-right', 'margin-bottom' and 'margin-left';

  * there are also some container properties that may be accessed directly or via a hash; for example, The 'font' accessor returns a hash containing 'font-size', 'font-family', and other font properties.

```raku
use CSS::Properties;

my CSS::Properties $css .= new: :style("color: orange; text-align: CENTER; margin: 2pt; font: 12pt Helvetica");

say $css.color.hex;       # (FF A5 00)
say $css.color.type;      # 'rgb'
say $css.text-align;      # 'center'
say $css.text-align.type; # 'keyw' (keyword)

# access margin-top, directly and through margin container
say $css.margin-top;      # '2'
say $css.margin-top.type; # 'pt'
say $css.margin;          # [2 2 2 2]
say $css.margin[0];       # '2'
say $css.margin[0].type;  # 'pt'

# access font-family directly and through font container
say $css.font-family;       # 'Helvetica'
say $css.font-family.type;  # 'ident'
say $css.font<font-family>; # 'Helvetica;
```

  * The simplest ways of setting a property is to assign a string value which is parsed as CSS.

  * Unit values are also recognized. E.g. `16pt`.

  * Colors can be assigned to color objects

  * Also the type and value can be assigned as a pair.

```raku
use CSS::Properties;
use CSS::Units :pt;
use Color;
my CSS::Properties $css .= new;

# assign to container
$css.font = "14pt Helvetica";

# assign to component properties
$css.font-weight = 'bold'; # string
$css.line-height = 16pt;   # unit value
$css.border-color = Color.new(0, 255, 0);
$css.font-style = :keyw<italic>; # type/value pair

say ~$css; # font:italic bold 14pt/16pt Helvetica;
```

Other Methods
-------------

### new

```raku
method new(
    Str :$style,
    CSS::Properties() :$inherit,
    CSS::Properties() :$copy,
    Str :$units = 'pt',
    Numeric :$em = $inherit.em // 12,
    Numeric :$viewport-width,
    Numeric :$viewport-height,
    Numeric :$reference-width,
    *%props,
) returns CSS::Properties
```

Options:

  * `Str :$style` CSS property list to parse

  * `CSS::Properties() :$inherit` Properties to be formally inherited

  * `CSS::Properties() :$copy` Additional properties to be copied in

  * `Str :$units` # measurement units, such as 'pt', 'px', 'in', etc

  * `Numeric :$em = 12` initial font size

  * `Numeric :$viewport-width` for use as `vw` length units

  * `Numeric :$viewport-height` for use as `vh` length units

  * `Numeric :$reference-width` for use in box values

  * `*%props` - CSS property settings

### measure

```raku
# Converts a value to a numeric quantity;
my Numeric $font-size = $css.measure: :font-size; # get current font size
$font-size = $css.measure: :font-size<smaller>;   # compute a smaller font
$font-size = $css.measure: :font-size(120%);      # compute a larger font
my $weight = $css.measure: :font-weight;          # get current font weight 100..900
$weight = $css.measure: :font-weight<bold>;       # compute bold font weight
```

This function is implemented for `font-size`, `font-weight`, `letter-spacing`, `line-height`, and `word-spacing`.

It also works for box related properties: `width`, `height`, `{min|max}-{width|height}`, `border-{top|right|bottom|left}-width`, and `{padding|margin}-{top|right|bottom|left}`. The `reference-width` attribute represents the width of a containing element; which needs to set for correct calculation of percentage box related quantities:

```raku
$css.reference-width = 80pt;
say $css.measure: :width(75%); # 60
```

### multi method info

```raku
multi method info(
    Str:D $prop-name
) returns CSS::Properties::PropertyInfo
```

return module meta-data for a property

### multi method handling

```raku
multi method handling(
    Str:D $prop
) returns CSS::Properties::Handling
```

return property value handling: 'initial', or 'inherit';

### multi method important

```raku
multi method important(
    Str $prop-name
) returns Mu
```

return True if the property has the !important attribute

### multi method important

```raku
multi method important() returns Mu
```

Return all properties that have the !important attribute

### sub alpha

```raku
sub alpha(
    $a
) returns Mu
```

convert 0 .. 255 => 0.0 .. 1.0. round to 2 decimal places

### multi method inherit

```raku
multi method inherit(
    CSS::Properties:D(Any):D $css
) returns Mu
```

CSS conformant inheritance from the given parent declaration list.

Note:

  * handling of 'initial' and 'inherit' in the child declarations

  * !important override properties in parent

  * not all properties are inherited. e.g. color is, margin isn't

### method set-properties

```raku
method set-properties(
    *%props
) returns Mu
```

set a list of properties as hash pairs

### method clone

```raku
method clone(
    *@decls,
    *%props
) returns Mu
```

create a deep copy of a CSS declarations object

### method ast

```raku
method ast(
    Bool :$optimize = Bool::True,
    Bool :$keep-defaults
) returns Mu
```

return an AST for the declarations.

This is more-or-less the inverse of the [CSS::Grammar::CSS3](https://css-raku.github.io/CSS-Grammar-raku) `declaration-list` rule, but with optimization. Suitable for reserialization with CSS::Writer

### method write

```raku
method write(
    Bool :$optimize = Bool::True,
    Bool :$color-names = Bool::True,
    Bool :$keep-defaults = Bool::False,
    Bool :$pretty = Bool::False,
    |c
) returns Mu
```

write a set of declarations.

By default, it is formatted as a single-line, suited to an HTML inline-style (style attribute).

### multi method properties

```raku
multi method properties(
    :$all! where { ... }
) returns Mu
```

return the names of all properties

### multi method properties

```raku
multi method properties() returns Mu
```

return the names of in-use properties

### method property-exists

```raku
method property-exists(
    Str $_
) returns Mu
```

True if the property has been set

### method delete

```raku
method delete(
    *@props
) returns Mu
```

delete property values from the list of populated properties

### method property

```raku
method property(
    Str \name
) returns Mu
```

returns the value of the named property

