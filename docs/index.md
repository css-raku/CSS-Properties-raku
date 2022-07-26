[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)

<a href="https://travis-ci.org/css-raku/CSS-Properties-raku"><img src="https://travis-ci.org/css-raku/CSS-Properties-raku.svg?branch=master"></a>
 <a href="https://ci.appveyor.com/project/dwarring/CSS-Properties-raku/branch/master"><img src="https://ci.appveyor.com/api/projects/status/github/css-raku/CSS-Properties-raku?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true"></a>

The CSS::Properties module is a set of related classes for parsing, manipulation and generation of CSS property sets, including inheritance, and defaults.

## Synopsis
```
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

Classes in this module
--------
  * [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties) - property list manipulation class.
  * [CSS::Properties::Calculator](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Calculator) - property calculator and measurement tool.
  * [CSS::Properties::Optimizer](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Optimizer) - property AST optimizer delegate
  * [CSS::Properties::PropertyInfo](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/PropertyInfo) - property meta-data delegate
  * [CSS::Box](https://css-raku.github.io/CSS-Properties-raku/CSS/Box) - CSS Box model implementation.
  * [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font) - property font manipulation
  * [CSS::Font::Descriptor](https://css-raku.github.io/CSS-Properties-raku/CSS/Font/Descriptor) - `@font-face` font descriptor objects
  * [CSS::Font::Pattern](https://css-raku.github.io/CSS-Properties-raku/CSS/Font/Pattern) - `@font-face` font patterns and matching
  * [CSS::PageBox](https://css-raku.github.io/CSS-Properties-raku/CSS/PageBox) - CSS Box model for paged media
  * [CSS::Units](https://css-raku.github.io/CSS-Properties-raku/CSS/Units) - units and post-fix operators (e.g. `12pt`)

See Also
--------

  * [CSS](https://css-raku.github.io/CSS-raku/) - Top level CSS manipulation class


## Conformance Levels

Processing defaults to CSS level 3 (class CSS::Module::CSS3). This can be configured via the :module option:

```
use CSS::Properties;
use CSS::Module;
use CSS::Module::CSS1;
use CSS::Module::CSS21;
use CSS::Module::CSS3;

my $style = 'color: red; azimuth: left';

my CSS::Module $module = CSS::Module::CSS1.module;
my CSS::Properties $css1 .= new: :$style, :$module;
## warnings: dropping unknown property: azimuth

$module = CSS::Module::CSS21.module;
my CSS::Properties $css21 .= new: :$style, :$module;
## (no warnings)

my CSS::Properties $css3 .= new: :$style; # CSS3 is the default
# -- or --
$module = CSS::Module::CSS3.module;
$css3 .= new: :$style, :$module;
```

### '@font-face' Properties

The [CSS::Font::Descriptor](https://css-raku.github.io/CSS-Properties-raku/CSS/Font/Descriptor) module is a class for managing `@font-face` declarations. The `css` method can be used to get the raw properties.

```
@font-face {
    font-family: myFirstFont;
    src: url(sansation_light.woff);
}
```

```
use CSS::Properties;
use CSS::Font::Descriptor;

my $style = "font-family: myFirstFont; src: url(sansation_light.woff)";
my CSS::Font::Descriptor $fd .= new: :$style;
my CSS::Properties $font-face-css = $fd.css;
```

## Default values

Most properties have a default value. If a property is reset to its default value it will be omitted from stringification:

    my $css = (require CSS::Properties).new;
    say $css.background-image; # none
    $css.background-image = 'url(camellia.png)';
    say ~$css; # "background-image: url(camellia.png);"
    $css.background-image = $css.info("background-image").default;
    say ~$css; # ""

## Deleting properties

Properties can be deleted via the `delete` method, or by assigning the property to `Nil`:

    my CSS::Properties $css .= new: :style("background-position:top left; border-top-color:red; border-bottom-color: green; color: blue");
    # delete background position
    $css.background-position = Nil;
    # delete all border colors
    $css.delete: "border-color";

## Inheritance

A child class can inherit from one or more parent classes. This follows CSS standards:

- not all properties are inherited by default; for example `color` is, but `margin` is not.

- the `inherit` keyword can be used in the child property to ensure inheritance.

- `initial` will reset the child property to the default value

To inherit a css object or style string:

- pass it as a `:inherit` option, when constructing the object, or

- use the `inherit` method

```
use CSS::Properties;

my $parent-style = "margin-top:5pt; margin-left: 15pt; color:rgb(0,0,255) !important";
my $style = "margin-top:25pt; margin-right: initial; margin-left: inherit; color:purple";
my CSS::Properties $css .= new: :$style, :inherit($parent-style);

say $css.color;                     # #7F007Frgb (purple)
say $css.handling("margin-left");   # inherit
say $css.margin-left;               # 15pt
```

## Optimization and Serialization

    method write(
        Bool :$optimize = True,        # consolidate properties
        Bool :$terse = True,           # single line output
        Bool :$color-names = True,     # use color names, where possible
        Bool :$keep-defaults = False,  # don't omit default values
        |c
    ) is also<Str gist> {


The `.write` (alias `.Str`, or .`gist`) method can be used to produce CSS. Properties are optimized and normalized:

- properties with default values are omitted

- multiple component properties are generally consolidated to container properties (e.g. `font-family: Courier` and `font-size: 12pt`
  are consolidated to `font: 12pt Courier`).

- rgb masks are translated to color-names, where possible

```
use CSS::Properties;
my CSS::Properties $css .= new( :style("background-repeat:repeat; border-style: groove; border-width: 2pt 2pt; color: rgb(255,0,0);") );
# - 'border-width' and 'border-style' are consolidated to the 'border' container property
# - rgb(255,0,0) is mapped to 'red'
say $css.write;  # "border:2pt groove; color: red;"
```

Notice that:

- `background-repeat` was omitted because it has the default value

- `border-style` and `border-width` have been consolidated to the `border` container property. This is possible
because all four borders have common values

- `color` has been translated from a color mask to a color

`$.write` Options include:

- `:!optimize` - turn off optimization. Don't, combine component properties into container properties (`border-style`, `border-width`, ... => `border`), or combine edges (`margin-top`, `margin-left`, ... => `margin`).

- `:!terse` - enable multi-line output

- `:!color-names` - don't translate RGB values to color-names

See also [CSS::Properties::Optimizer](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Optimizer).

## Property Meta-data

The `info` method gives property specific meta-data, on all (component or container properties). It returns an object of type CSS::Properties::PropertyInfo:

```
use CSS::Properties;
my CSS::Properties $css .= new;
my $margin-info = $css.info("margin");
say $margin-info.synopsis; # <margin-width>{1,4}
say $margin-info.edges;    # [margin-top margin-right margin-bottom margin-left]
say $margin-info.inherit;  # True (property is inherited)
```

## Data Introspection

The `properties` method, gives a list of current properties. Only component properties
are returned. E.g. `font-family` may be returned; but `font` never is.

```
use CSS::Properties;

my $style = "margin-top: 10%; margin-right: 5mm; margin-bottom: auto";
my CSS::Properties $css .= new: :$style;

for $css.properties -> $prop {
    my $val = $css."$prop"();
    say "$prop: $val {$val.type}";
}

```
Gives:
```
margin-top: 10 percent
margin-bottom: auto keyw
margin-right: 5 mm
```

## Length Units

CSS::Units is a convenience module that provides some simple post-fix length unit definitions.

The `:ops` export overloads  `+` and `-` to perform unit
calculations. `+css` and `-css` are also available as
more explicit infix operators:

All infix operators convert to the left-hand operand's units.

```
use CSS::Units :ops, :pt, :px, :in, :mm;
my $css = (require CSS::Properties).new: :margin[5pt, 10px, .1in, 2mm];

# display margins in millimeters
say "%.2f mm".sprintf(.scale("mm")) for $css.margin.list;
```

## Appendix : CSS3 Properties

Name | Default | Inherit | Type | Synopsis
--- | --- | --- | --- | ---
azimuth | center | Yes |  | \<angle\> \| [[ left-side \| far-left \| left \| center-left \| center \| center-right \| right \| far-right \| right-side ] \|\| behind ] \| leftwards \| rightwards
background |  |  | hash | ['background-color' \|\| 'background-image' \|\| 'background-repeat' \|\| 'background-attachment' \|\| 'background-position']
background-attachment | scroll |  |  | scroll \| fixed
background-color | transparent |  |  | \<color\> \| transparent
background-image | none |  |  | \<uri\> \| none
background-position | 0% 0% |  |  | [ [ \<percentage\> \| \<length\> \| left \| center \| right ] [ \<percentage\> \| \<length\> \| top \| center \| bottom ]? ] \| [ [ left \| center \| right ] \|\| [ top \| center \| bottom ] ]
background-repeat | repeat |  |  | repeat \| repeat-x \| repeat-y \| no-repeat
border |  |  | hash,box | [ 'border-width' \|\| 'border-style' \|\| 'border-color' ]
border-bottom |  |  | hash | [ 'border-bottom-width' \|\| 'border-bottom-style' \|\| 'border-bottom-color' ]
border-bottom-color | the value of the 'color' property |  |  | \<color\> \| transparent
border-bottom-style | none |  |  | \<border-style\>
border-bottom-width | medium |  |  | \<border-width\>
border-collapse | separate | Yes |  | collapse \| separate
border-color |  |  | box | [ \<color\> \| transparent ]{1,4}
border-left |  |  | hash | [ 'border-left-width' \|\| 'border-left-style' \|\| 'border-left-color' ]
border-left-color | the value of the 'color' property |  |  | \<color\> \| transparent
border-left-style | none |  |  | \<border-style\>
border-left-width | medium |  |  | \<border-width\>
border-right |  |  | hash | [ 'border-right-width' \|\| 'border-right-style' \|\| 'border-right-color' ]
border-right-color | the value of the 'color' property |  |  | \<color\> \| transparent
border-right-style | none |  |  | \<border-style\>
border-right-width | medium |  |  | \<border-width\>
border-spacing | 0 | Yes |  | \<length\> \<length\>?
border-style |  |  | box | \<border-style\>{1,4}
border-top |  |  | hash | [ 'border-top-width' \|\| 'border-top-style' \|\| 'border-top-color' ]
border-top-color | the value of the 'color' property |  |  | \<color\> \| transparent
border-top-style | none |  |  | \<border-style\>
border-top-width | medium |  |  | \<border-width\>
border-width |  |  | box | \<border-width\>{1,4}
bottom | auto |  |  | \<length\> \| \<percentage\> \| auto
caption-side | top | Yes |  | top \| bottom
clear | none |  |  | none \| left \| right \| both
clip | auto |  |  | \<shape\> \| auto
color | depends on user agent | Yes |  | \<color\>
content | normal |  |  | normal \| none \| [ \<string\> \| \<uri\> \| \<counter\> \| \<counters\> \| attr(\<identifier\>) \| open-quote \| close-quote \| no-open-quote \| no-close-quote ]+
counter-increment | none |  |  | none \| [ \<identifier\> \<integer\>? ]+
counter-reset | none |  |  | none \| [ \<identifier\> \<integer\>? ]+
cue |  |  | hash | [ 'cue-before' \|\| 'cue-after' ]
cue-after | none |  |  | \<uri\> \| none
cue-before | none |  |  | \<uri\> \| none
cursor | auto | Yes |  | [ [\<uri\> ,]* [ auto \| crosshair \| default \| pointer \| move \| e-resize \| ne-resize \| nw-resize \| n-resize \| se-resize \| sw-resize \| s-resize \| w-resize \| text \| wait \| help \| progress ] ]
direction | ltr | Yes |  | ltr \| rtl
display | inline |  |  | inline \| block \| list-item \| inline-block \| table \| inline-table \| table-row-group \| table-header-group \| table-footer-group \| table-row \| table-column-group \| table-column \| table-cell \| table-caption \| none
elevation | level | Yes |  | \<angle\> \| below \| level \| above \| higher \| lower
empty-cells | show | Yes |  | show \| hide
float | none |  |  | left \| right \| none
font |  | Yes | hash | [ [ \<‘font-style’\> \|\| \<font-variant-css21\> \|\| \<‘font-weight’\> \|\| \<‘font-stretch’\> ]? \<‘font-size’\> [ / \<‘line-height’\> ]? \<‘font-family’\> ] \| caption \| icon \| menu \| message-box \| small-caption \| status-bar
font-family | depends on user agent | Yes |  | [ \<generic-family\> \| \<family-name\> ]\#
font-feature-settings | normal | Yes |  | normal \| \<feature-tag-value\>\#
font-kerning | auto | Yes |  | auto \| normal \| none
font-language-override | normal | Yes |  | normal \| \<string\>
font-size | medium | Yes |  | \<absolute-size\> \| \<relative-size\> \| \<length\> \| \<percentage\>
font-size-adjust | none | Yes |  | none \| auto \| \<number\>
font-stretch | normal | Yes |  | normal \| ultra-condensed \| extra-condensed \| condensed \| semi-condensed \| semi-expanded \| expanded \| extra-expanded \| ultra-expanded
font-style | normal | Yes |  | normal \| italic \| oblique
font-synthesis | weight style | Yes |  | none \| [ weight \|\| style ]
font-variant | normal | Yes |  | normal \| none \| [ \<common-lig-values\> \|\| \<discretionary-lig-values\> \|\| \<historical-lig-values\> \|\| \<contextual-alt-values\> \|\| stylistic(\<feature-value-name\>) \|\| historical-forms \|\| styleset(\<feature-value-name\> \#) \|\| character-variant(\<feature-value-name\> \#) \|\| swash(\<feature-value-name\>) \|\| ornaments(\<feature-value-name\>) \|\| annotation(\<feature-value-name\>) \|\| [ small-caps \| all-small-caps \| petite-caps \| all-petite-caps \| unicase \| titling-caps ] \|\| \<numeric-figure-values\> \|\| \<numeric-spacing-values\> \|\| \<numeric-fraction-values\> \|\| ordinal \|\| slashed-zero \|\| \<east-asian-variant-values\> \|\| \<east-asian-width-values\> \|\| ruby ]
font-variant-alternates | normal | Yes |  | normal \| [ stylistic(\<feature-value-name\>) \|\| historical-forms \|\| styleset(\<feature-value-name\>\#) \|\| character-variant(\<feature-value-name\>\#) \|\| swash(\<feature-value-name\>) \|\| ornaments(\<feature-value-name\>) \|\| annotation(\<feature-value-name\>) ]
font-variant-caps | normal | Yes |  | normal \| small-caps \| all-small-caps \| petite-caps \| all-petite-caps \| unicase \| titling-caps
font-variant-east-asian | normal | Yes |  | normal \| [ \<east-asian-variant-values\> \|\| \<east-asian-width-values\> \|\| ruby ]
font-variant-ligatures | normal | Yes |  | normal \| none \| [ \<common-lig-values\> \|\| \<discretionary-lig-values\> \|\| \<historical-lig-values\> \|\| \<contextual-alt-values\> ]
font-variant-numeric | normal | Yes |  | normal \| [ \<numeric-figure-values\> \|\| \<numeric-spacing-values\> \|\| \<numeric-fraction-values\> \|\| ordinal \|\| slashed-zero ]
font-variant-position | normal | Yes |  | normal \| sub \| super
font-weight | normal | Yes |  | normal \| bold \| bolder \| lighter \| 100 \| 200 \| 300 \| 400 \| 500 \| 600 \| 700 \| 800 \| 900
height | auto |  |  | \<length\> \| \<percentage\> \| auto
left | auto |  |  | \<length\> \| \<percentage\> \| auto
letter-spacing | normal | Yes |  | normal \| \<length\>
line-height | normal | Yes |  | normal \| \<number\> \| \<length\> \| \<percentage\>
list-style |  | Yes | hash | [ 'list-style-type' \|\| 'list-style-position' \|\| 'list-style-image' ]
list-style-image | none | Yes |  | \<uri\> \| none
list-style-position | outside | Yes |  | inside \| outside
list-style-type | disc | Yes |  | disc \| circle \| square \| decimal \| decimal-leading-zero \| lower-roman \| upper-roman \| lower-greek \| lower-latin \| upper-latin \| armenian \| georgian \| lower-alpha \| upper-alpha \| none
margin |  |  | box | \<margin-width\>{1,4}
margin-bottom | 0 |  |  | \<margin-width\>
margin-left | 0 |  |  | \<margin-width\>
margin-right | 0 |  |  | \<margin-width\>
margin-top | 0 |  |  | \<margin-width\>
max-height | none |  |  | \<length\> \| \<percentage\> \| none
max-width | none |  |  | \<length\> \| \<percentage\> \| none
min-height | 0 |  |  | \<length\> \| \<percentage\>
min-width | 0 |  |  | \<length\> \| \<percentage\>
opacity | 1.0 |  |  | \<number\>
orphans | 2 | Yes |  | \<integer\>
outline |  |  | hash | [ 'outline-color' \|\| 'outline-style' \|\| 'outline-width' ]
outline-color | invert |  |  | \<color\> \| invert
outline-style | none |  |  | [ none \| hidden \| dotted \| dashed \| solid \| double \| groove \| ridge \| inset \| outset ]
outline-width | medium |  |  | thin \| medium \| thick \| \<length\>
overflow | visible |  |  | visible \| hidden \| scroll \| auto
padding |  |  | box | \<padding-width\>{1,4}
padding-bottom | 0 |  |  | \<padding-width\>
padding-left | 0 |  |  | \<padding-width\>
padding-right | 0 |  |  | \<padding-width\>
padding-top | 0 |  |  | \<padding-width\>
page-break-after | auto |  |  | auto \| always \| avoid \| left \| right
page-break-before | auto |  |  | auto \| always \| avoid \| left \| right
page-break-inside | auto |  |  | avoid \| auto
pause |  |  |  | [ [\<time\> \| \<percentage\>]{1,2} ]
pause-after | 0 |  |  | \<time\> \| \<percentage\>
pause-before | 0 |  |  | \<time\> \| \<percentage\>
pitch | medium | Yes |  | \<frequency\> \| x-low \| low \| medium \| high \| x-high
pitch-range | 50 | Yes |  | \<number\>
play-during | auto |  |  | \<uri\> [ mix \|\| repeat ]? \| auto \| none
position | static |  |  | static \| relative \| absolute \| fixed
quotes | depends on user agent | Yes |  | [\<string\> \<string\>]+ \| none
richness | 50 | Yes |  | \<number\>
right | auto |  |  | \<length\> \| \<percentage\> \| auto
size | auto |  |  | \<length\>{1,2} \| auto \| [ \<page-size\> \|\| [ portrait \| landscape] ]
speak | normal | Yes |  | normal \| none \| spell-out
speak-header | once | Yes |  | once \| always
speak-numeral | continuous | Yes |  | digits \| continuous
speak-punctuation | none | Yes |  | code \| none
speech-rate | medium | Yes |  | \<number\> \| x-slow \| slow \| medium \| fast \| x-fast \| faster \| slower
stress | 50 | Yes |  | \<number\>
table-layout | auto |  |  | auto \| fixed
text-align | a nameless value that acts as 'left' if 'direction' is 'ltr', 'right' if 'direction' is 'rtl' | Yes |  | left \| right \| center \| justify
text-decoration | none |  |  | none \| [ underline \|\| overline \|\| line-through \|\| blink ]
text-indent | 0 | Yes |  | \<length\> \| \<percentage\>
text-transform | none | Yes |  | capitalize \| uppercase \| lowercase \| none
top | auto |  |  | \<length\> \| \<percentage\> \| auto
unicode-bidi | normal |  |  | normal \| embed \| bidi-override
vertical-align | baseline |  |  | baseline \| sub \| super \| top \| text-top \| middle \| bottom \| text-bottom \| \<percentage\> \| \<length\>
visibility | visible | Yes |  | visible \| hidden \| collapse
voice-family | depends on user agent | Yes |  | [\<generic-voice\> \| \<specific-voice\> ]\#
volume | medium | Yes |  | \<number\> \| \<percentage\> \| silent \| x-soft \| soft \| medium \| loud \| x-loud
white-space | normal | Yes |  | normal \| pre \| nowrap \| pre-wrap \| pre-line
widows | 2 | Yes |  | \<integer\>
width | auto |  |  | \<length\> \| \<percentage\> \| auto
word-spacing | normal | Yes |  | normal \| \<length\>
z-index | auto |  |  | auto \| \<integer\>


The above markdown table was produced with the following code snippet

```
use v6;
say <Name Default Inherit Type Synopsis>.join(' | ');
say ('---' xx 5).join(' | ');

my $css = (require CSS::Properties).new;

for $css.properties(:all).sort -> $name {
    with $css.info($name) {
        my @type;
        @type.push: 'hash' if .children;
        @type.push: 'box' if .box;
        my $synopsis-escaped = .synopsis.subst(/<?before <[ < | > # ]>>/, '\\', :g); 

        say ($name,
             .default // '',
             .inherit ?? 'Yes' !! '',
             @type.join(','),
             $synopsis-escaped,
            ).join(' | ');
    }
}

```
