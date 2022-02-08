[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Box](https://css-raku.github.io/CSS-Properties-raku/CSS/Box)

class CSS::Box
--------------

Abstract class for handling CSS Box Model elements

Synopsis
--------

```raku
use CSS::Box;
use CSS::Units :px, :pt, :em, :percent;
use CSS::Properties;

my $style = q:to"END";
    width:   300px;
    border:  25px solid green;
    padding: 25px;
    margin:  25px;
    font:    italic bold 10pt/12pt times-roman;
    END

my CSS::Properties $css .= new: :$style;
my $top    = 80pt;
my $right  = 50pt;
my $bottom = 10pt;
my $left   = 10pt;

my CSS::Box $box .= new( :$top, :$left, :$bottom, :$right, :$css );
say $box.padding;           # dimensions of padding box;
say $box.margin;            # dimensions of margin box;
say $box.border-right;      # vertical position of right border
say $box.border-width;      # border-right - border-left
say $box.width("border");   # border-width
say $box.height("content"); # height of content box

say $box.font.family;        # 'times-roman'
# calculate some relative font lengths
say $box.font-length(1.5em);    # 15
say $box.font-length(200%);     # 20
say $box.font-length('larger'); # 12
```

Box Model
---------

### Overview

Excerpt from [CSS 2.2 Specification Chapter 8 - Box Model](https://www.w3.org/TR/CSS22/box.html#box-dimensions):

![Box Model](boxdim.png)

The margin, border, and padding can be broken down into top, right, bottom, and left segments (e.g., in the diagram, "LM" for left margin, "RP" for right padding, "TB" for top border, etc.).

The perimeter of each of the four areas (content, padding, border, and margin) is called an "edge", so each box has four edges:

  * **Content Edge** or **Inner Edge** - The content edge surrounds the rectangle given by the width and height of the box, which often depend on the element's rendered content. The four content edges define the box's content box.

  * **Padding Edge** - The padding edge surrounds the box padding. If the padding has 0 width, the padding edge is the same as the content edge. The four padding edges define the box's padding box.

  * **Border Edge** - The border edge surrounds the box's border. If the border has 0 width, the border edge is the same as the padding edge. The four border edges define the box's border box.

  * **Margin Edge** or **Outer Edge** - The margin edge surrounds the box margin. If the margin has 0 width, the margin edge is the same as the border edge. The four margin edges define the box's margin box.

Methods head3 new
-----------------

```raku
method new(
    Numeric :$top, Numeric :$bottom, Numeric :$height
    Numeric :$left, Numeric :$right, Numeric :$width,
    CSS::Properties :$css!,
) returns CSS::Box;
```

The box `new` constructor accepts:

    - any two of `:top`, `:bottom` or `:height`,

    - and any two of `:left`, `:right` or `:width`.

### font method font() returns CSS::Font; say "font-size is {$box.font.em}";

The '.font' accessor returns an object of type [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font), with accessor methods: `em`, `ex`, `weight`, `family`, `style`, `leading`, `find-font`, `fontconfig-pattern` and `measure` methods.

### measure method measure(|) returns Numeric;

This method converts various length units to normalized base units (default 'pt').

    use CSS::Units :mm, :in, :pt, :px;
    use CSS::Box;
    use CSS::Properties;
    my CSS::Box $box .= new;
    # default base units is points
    say [(1mm, 1in, 1pt, 1px).map: {$box.measure($_)}];
    # produces: [2.8346pt 72pt 1pt 0.75pt]
    # change base units to inches
    $box .= new: :units<in>;
    say [(1in, 72pt).map: {$box.measure($_)}];
    # produces: [1in, 1in]

See also [CSS::Properties::Calculator](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Calculator)

### top, right, bottom, left

These methods return measured positions of each of the four corners of the inner content box. They are rw accessors, e.g.:

    $box.top += 5;

Outer boxes will grow and shrink, retaining their original width and height.

### padding, margin, border

These method return all four corners (measured) of the given box, e.g.:

    my Numeric ($top, $right, $bottom, $left) = $box.padding

### content

This returns all four corners (measured) of the content box, e.g.:

    my Numeric ($top, $right, $bottom, $left) = $box.content;

These values are rw. The box can be both moved and resized, by adjusting this array.

    $box.content = (10, 50, 35, 10); # 40x25 box, top-left @ 10,10

Outer boxes, will grow or shrink to retain their original widths.

### [padding|margin|border|content]-[width|height]

    say "margin box is size {$box.margin-width} X {$box.margin-height}";

This family of accessors return the measured width, or height of the given box.

### [padding|margin|border|content]-[top|right|bottom|left]

    say "margin left, top is ({$box.margin-left}, {$box.margin-top})";

This family of accessors return the measured x or y position of the given edge

### translate, move

These methods can be used to adjust the position of the content box.

    $box.translate(10, 20); # translate box 10, 20 in X, Y directions
    $box.move(40, 50); # move top left corner to (X, Y) = (40, 50)

