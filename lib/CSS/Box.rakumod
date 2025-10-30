#| Abstract class for handling CSS Box Model elements
unit class CSS::Box;

use CSS::Properties;
use CSS::Units :pt, :ops;
use Method::Also;
my Int enum Edges is export(:Edges) <Top Right Bottom Left>;
class Rect is rw is repr('CStruct') {
    has num32 $.top;
    has num32 $.right;
    has num32 $.bottom;
    has num32 $.left = 0e0;
    submethod TWEAK is hidden-from-backtrace  {
        die "top($!top) < bottom($!bottom)"
            unless $!top >= $!bottom;
        die "right($!right) < left($!left)"
            unless $!right >= $!left;
    }
    method width {$!right - $!left}
    method height {$!top - $!bottom}
    method enclose(::?CLASS:D: $top, $right, $bottom, $left) {
        my $obj = self.clone;
        $obj.top    += $top;
        $obj.right  += $right;
        $obj.bottom -= $bottom;
        $obj.left   -= $left;
        $obj;
    }
    method clone(::?CLASS:D:) { self.new: :$!top, :$!left, :$!bottom, :$!right; }
    method List is also<list> handles <Array> { ($!top, $!right, $!bottom, $!left) }
}
has Rect $!content;
has Rect $!padding;
has Rect $!border;
has Rect $!margin;

use CSS::Font;
has CSS::Font $.font is rw handles <font-size measure units em ex viewport-width viewport-height font-props>;
has CSS::Properties() $.css;

has Hash @.save;

my subset BoundingBox of Str where 'content'|'border'|'margin'|'padding';

submethod TWEAK(
    Numeric:D :$width is copy = 595pt,
    Numeric:D :$height is copy = 842pt,
    Num() :$left = 0e0,
    Num() :$top is copy,
    Num() :$bottom is copy,
    Num() :$right is copy,
    Str:D :$style = '',
    :font($),
    |c
) {
    $!css //= CSS::Properties.new(:$style, |c);
    $!font //= CSS::Font.new: :$!css;
    $width = self.measure: $width;
    $height = self.measure: $height;
    $top //= $height;
    $bottom //= $top - $height;
    $right //= $left + $width;
    $!content .= new: :$top, :$left, :$bottom, :$right;
    self!resize;
}

method !resize {
    die "left > right" if $.left > $.right;
    die "bottom > top" if $.bottom > $.top;
    $!padding = Nil;
    $!border = Nil;
    $!margin = Nil;
}

multi method top is rw { $!content.top }
multi method top(BoundingBox $box) is rw {
    self."$box"().top
}

multi method right is rw { $!content.right }
multi method right(BoundingBox $box = $!content) is rw {
    self."$box"().right;
}

multi method bottom is rw { $!content.bottom }
multi method bottom(BoundingBox $box) is rw {
    self."$box"().bottom;
}

multi method left is rw { $!content.left }
multi method left(BoundingBox $box) is rw {
    self."$box"().left;
}

multi method width { $!content.width }
multi method width(BoundingBox $box) {
    self."$box"().width;
}

multi method height { $!content.height }
multi method height(BoundingBox $box) {
    self."$box"().height
}

method measurements(List $qtys, Numeric:D :$ref = 0) {
    [ $qtys.map: { self.measure($_, :$ref) } ]
}

method padding returns Rect {
    my $ref := $!css.reference-width;
    $!padding //= $.content.enclose: |self.measurements($!css.padding, :$ref);
}
method border returns Rect {
    $!border //= $.padding.enclose: |self.measurements($!css.border-width, :ref(0));
}
method margin returns Rect {
    my $ref := $!css.reference-width;
    $!margin //= $.border.enclose: |self.measurements($!css.margin, :$ref);
}

method content returns Rect is rw { $!content }

method Array is rw {
    Proxy.new(
        FETCH => sub ($) {
            $!content.Array;
        },
        STORE => sub ($,@v) {
            my $width  = $.width;
            my $height = $.height;
            $.top    = .Num with @v[Top];
            $.right  = .Num with @v[Right];
            $.bottom = (@v[Bottom] // $.top - $height).Num;
            $.left   = (@v[Left] // $.right - $width).Num;
            self!resize;
        });
}

method move( \x, \y) {
    self.Array = [y, x ];
}

method translate( \x, \y) {
    self.Array = [ $.top + y, $.right + x ];
}

method save {
    @!save.push: {
        :$!font,
    }
    $!font .= clone;
}

method restore {
    if @!save {
        with @!save.pop {
            $!font     = .<font>;
        }
    }
}

has %!meths;
method can(Str \name) {
   callsame() || %!meths{name} //= do {
       given name {
           when /^ (padding|border|margin)'-'(top|right|bottom|left) $/ {
               # absolute positions
               my Str $box = ~$0;
               my Str $edge = ~$1;
               ( method { self."$box"()."$edge"() }, );
           }
           when /^ (padding|border|margin)'-'(width|height) $/ {
               # cumulative widths and heights
               my Str $box = ~$0;
               my &meth :=  $1 eq 'width'
                     ??  method { .width with self."$box"() }
                     !!  method { .height with self."$box"() };
               ( &meth, );
           }
           default { () }
       }
   }
}
method dispatch:<.?>(\name, |c) is raw {
    given self.can(name) {
        .so ?? .[0](self, |c) !! Nil;
    }
}
method FALLBACK(Str \name, |c) {
    given self.can(name) {
        .so ?? .[0](self, |c)
            !! die X::Method::NotFound.new: :method(name), :typename(self.^name);
    }
}

=begin pod
=head2 Synopsis
=begin code :lang<raku>
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

my CSS::Properties $css .= new: :$style, :units<pt>;
my $top    = 80;
my $right  = 50;
my $bottom = 10;
my $left   = 10;

my CSS::Box $box .= new: :$top, :$left, :$bottom, :$right, :$css;
say $box.units;             # pt
say $box.padding.Array;     # dimensions of padding box (px)
say $box.margin.Array;      # dimensions of margin box;
say $box.border-right;      # vertical position of right border
say $box.border-width;      # border-right - border-left
say $box.width("border");   # border-width
say $box.height("content"); # height of content box

say $box.font.style.fmt;    # "italic"
say $box.font.family.fmt;   # "times-roman"
# calculate some relative font lengths
say $box.measure: :font-size;           # 10pt
say $box.measure: :font-size(1.5em);    # 15pt
say $box.measure: :font-size(200%);     # 20pt
say $box.measure: :font-size<larger>;   # 12pt
=end code

=head2 Box Model

=head3 Overview

Excerpt from L<CSS 2.2 Specification Chapter 8 - Box Model|https://www.w3.org/TR/CSS22/box.html#box-dimensions>:

![Box Model](boxdim.png)

The margin, border, and padding can be broken down into top, right, bottom, and left segments (e.g., in the diagram, "LM" for left margin, "RP" for right padding, "TB" for top border, etc.).

The perimeter of each of the four areas (content, padding, border, and margin) is called an "edge", so each box has four edges:

=item B<Content Edge> or B<Inner Edge> - 
  The content edge surrounds the rectangle given by the width and height of the box, which often depend on the element's rendered content. The four content edges define the box's content box.

=item B<Padding Edge> -
The padding edge surrounds the box padding. If the padding has 0 width, the padding edge is the same as the content edge. The four padding edges define the box's padding box.

=item B<Border Edge> -
The border edge surrounds the box's border. If the border has 0 width, the border edge is the same as the padding edge. The four border edges define the box's border box.

=item B<Margin Edge> or B<Outer Edge> -
The margin edge surrounds the box margin. If the margin has 0 width, the margin edge is the same as the border edge. The four margin edges define the box's margin box.

=head2 Methods
head3 new
=begin code :lang<raku>
method new(
    Numeric :$top, Numeric :$bottom, Numeric :$height
    Numeric :$left, Numeric :$right, Numeric :$width,
    CSS::Properties :$css!,
) returns CSS::Box;
=end code

The box `new` constructor accepts:

  - any two of `:top`, `:bottom` or `:height`,

  - and any two of `:left`, `:right` or `:width`.

=head3 font
    method font() returns CSS::Font;
    say "font-size is {$box.font.em}";

The '.font' accessor returns an object of type L<CSS::Font>, with accessor methods: `em`, `ex`, `weight`, `family`, `style`, `leading`, `find-font`, `fontconfig-pattern` and `measure` methods.

=head3 measure
    method measure(|) returns Numeric;

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

See also L<CSS::Properties::Calculator>

=head3 top, right, bottom, left

These methods return measured positions of each of the four corners of the inner content box. They
are rw accessors, e.g.:

    $box.top += 5;

The size of the enclosing rectangles (padding, margin, border) also changes; enclosing edges remaining fixed.

=head3 content, padding, margin, border

These methods return a CSS::Properties::Box::Rect objects of the given enclosing box, e.g.:

    my CSS::Properties::Box::Rect $padding = $box.padding;
    my Numeric $top = $padding.left;

These values are rw. The box can be both moved and resized, by adjusting this array.

    $box.content.Array = (10, 50, 35, 10); # 40x25 box, top-left @ 10,10

Enclosing rectangles, will grow or shrink; enclosing edges remain fixed.

=head3 [padding|margin|border|content]-[width|height]

     say "margin box is size {$box.margin-width} X {$box.margin-height}";

This family of accessors return the measured width, or height of the given box.

=head3 [padding|margin|border|content]-[top|right|bottom|left]

     say "margin left, top is ({$box.margin-left}, {$box.margin-top})";

This family of accessors return the measured x or y position of the given edge

=head3 translate, move

These methods can be used to adjust the position of the content box.

    $box.translate(10, 20); # translate box 10, 20 in X, Y directions
    $box.move(40, 50); # move top left corner to (X, Y) = (40, 50)

=end pod
