class CSS::Properties
---------------------

management class for a set of CSS Properties

Synopsis
--------

```raku
use CSS::Units :pt;
use CSS::Properties;

my $style = "color:red !important; padding: 1pt";
my CSS::Properties $css .= new( :$style );
say $css.important("color"); # True
$css.border-color = 'red';

$css.margin = [5pt, 2pt, 5pt, 2pt];
$css.margin = 5pt;  # set margin on all 4 sides

# set text alignment
$css.text-align = 'right';

say ~$css; # border-color:red; color:red!important; margin:5pt; padding:1pt; text-align:right;
```

Description This classes manages a list of properties. These are typically parsed from the body of a CSS rule-set or from an inline `style` tag.
------------------------------------------------------------------------------------------------------------------------------------------------

### has Positional[Exception] @.warnings

associated CSS module

Methods
-------

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

### multi method info

```raku
multi method info(
    Str:D $prop-name
) returns Mu
```

return module meta-data for a property

### method default

```raku
method default(
    $prop
) returns Mu
```

return the default value for the property

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

return true of the property has the !important attribute

### multi sub from-ast

```raku
multi sub from-ast(
    Hash $v where { ... }
) returns Mu
```

{ :int(42) } => :int(42)

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

CSS conformant inheritance from the given parent declaration list. Note: - handling of 'initial' and 'inherit' in the child declarations - !important override properties in parent - not all properties are inherited. e.g. color is, margin isn't

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

return an AST for the declarations. This is more-or-less the inverse of CSS::Grammar::CSS3::declaration-list>, but with optimization. Suitable for reserialization with CSS::Writer

### method write

```raku
method write(
    Bool :$optimize = Bool::True,
    Bool :$terse = Bool::True,
    Bool :$color-names = Bool::True,
    Bool :$keep-defaults = Bool::False,
    |c
) returns Mu
```

write a set of declarations. By default, it is formatted as a single-line, suited to an HTML inline-style (style attribute).

### multi method properties

```raku
multi method properties(
    :$all! where { ... }
) returns Mu
```

return all known module properties

### multi method properties

```raku
multi method properties() returns Mu
```

return in-use properties

### method delete

```raku
method delete(
    *@props
) returns Mu
```

delete property values from the list of populated properties

