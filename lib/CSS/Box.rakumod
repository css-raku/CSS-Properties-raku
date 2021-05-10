use v6;

#| Abstract class for handling CSS Box Model elements
class CSS::Box {
    use CSS::Properties;
    use CSS::Units :pt, :ops;
    my Int enum Edges is export(:Edges) <Top Right Bottom Left>;
    has Numeric $.top;
    has Numeric $.right;
    has Numeric $.bottom;
    has Numeric $.left = 0;

    has Array $!padding;
    has Array $!border;
    has Array $!margin;

    use CSS::Font;
    has CSS::Font $.font is rw handles <font-size measure units em ex viewport-width viewport-height>;
    has CSS::Properties $.css;

    has Hash @.save;

    my subset BoundingBox of Str where 'content'|'border'|'margin'|'padding';

    submethod TWEAK(
        Numeric :$width = 595pt,
        Numeric :$height = 842pt,
        Numeric :$!top = $height,
        Numeric :$!bottom = $!top - $height,
        Numeric :$!right = $!left + $width,
        Str :$style = '',
        :font($),
        |c
    ) {
        $!css //= CSS::Properties.new(:$style, |c);
        $!font //= CSS::Font.new: :$!css;
        self!resize;
    }

    method !resize {
        die "left > right" if $!left > $!right;
        die "bottom > top" if $!bottom > $!top;
        $!padding = Nil;
        $!border = Nil;
        $!margin = Nil;
    }

    multi method top is rw {
        Proxy.new(
            FETCH => sub ($) { $!top },
            STORE => sub ($, $!top) { self!resize },
            );
    }

    multi method top(BoundingBox $box) is rw {
        self."$box"()[Top];
    }

    multi method right is rw { $!right }
    multi method right(BoundingBox $box) is rw {
        self."$box"()[Right];
    }

    multi method bottom is rw { $!bottom }
    multi method bottom(BoundingBox $box) is rw {
        self."$box"()[Bottom]
    }

    multi method left is rw { $!left }
    multi method left(BoundingBox $box) is rw {
        self."$box"()[Left]
    }

    multi method width { $!right - $!left }
    multi method width(BoundingBox $box) {
        my \box = self."$box"();
        box[Right] - box[Left]
    }

    multi method height { $!top - $!bottom }
    multi method height(BoundingBox $box) {
        my \box = self."$box"();
        box[Top] - box[Bottom]
    }

    method measurements(List $qtys, Numeric:D :$ref = 0) {
        [ $qtys.map: { self.measure($_, :$ref) } ]
    }

    method padding returns Array {
        my $ref := $!css.reference-width;
        $!padding //= self!enclose: $.Array, self.measurements($!css.padding, :$ref);
    }
    method border returns Array {
        $!border //= self!enclose: $.padding, self.measurements($!css.border-width, :ref(0));
    }
    method margin returns Array {
        my $ref := $!css.reference-width;
        $!margin //= self!enclose: $.border, self.measurements($!css.margin, :$ref);
    }

    method content returns Array is rw { self.Array }

    method !enclose(List $inner, List $outer) {
        [
         $inner[Top]    + $outer[Top],
         $inner[Right]  + $outer[Right],
         $inner[Bottom] - $outer[Bottom],
         $inner[Left]   - $outer[Left],
        ]
    }

    method Array is rw {
        Proxy.new(
            FETCH => sub ($) {
                [$!top, $!right, $!bottom, $!left]
            },
            STORE => sub ($,@v) {
                my $width  = $!right - $!left;
                my $height = $!top - $!bottom;
                $!top    = $_ with @v[Top];
                $!right  = $_ with @v[Right];
                $!bottom = @v[Bottom] // $!top - $height;
                $!left   = @v[Left] // $!right - $width;
                self!resize;
            });
    }

    method move( \x, \y) {
        self.Array = [y, x ];
    }

    method translate( \x, \y) {
        self.Array = [ $!top + y, $!right + x ];
    }

    method save {
        @!save.push: {
            :$!font,
        }
        $!font = $!font.clone;
    }

    method restore {
        if @!save {
            with @!save.pop {
                $!font     = .<font>;
            }
        }
    }

    method can(Str \name) {
       callsame() || do {
           given name {
               when /^ (padding|border|margin)'-'(top|right|bottom|left) $/ {
                   # absolute positions
                   my Str $box = ~$0;
                   my UInt \edge = %( :top(Top), :right(Right), :bottom(Bottom), :left(Left) ){$1};
                   ( method { self."$box"()[edge] }, );
               }
               when /^ (padding|border|margin)'-'(width|height) $/ {
                   # cumulative widths and heights
                   my Str $box = ~$0;
                   my &meth :=  $1 eq 'width'
                         ??  method { .[Right] - .[Left] with self."$box"() }
                         !!  method { .[Top] - .[Bottom] with self."$box"() };
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

See also L<CSS::Propertues::Calculator>

=head3 top, right, bottom, left

These methods return measured positions of each of the four corners of the inner content box. They
are rw accessors, e.g.:

    $box.top += 5;

Outer boxes will grow and shrink, retaining their original width and height.

=head3 padding, margin, border

These method return all four corners (measured) of the given box, e.g.:

    my Numeric ($top, $right, $bottom, $left) = $box.padding


=head3 content

This returns all four corners (measured) of the content box, e.g.:

    my Numeric ($top, $right, $bottom, $left) = $box.content;

These values are rw. The box can be both moved and resized, by adjusting this array.

    $box.content = (10, 50, 35, 10); # 40x25 box, top-left @ 10,10

Outer boxes, will grow or shrink to retain their original widths.

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
