use v6;

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

    use CSS::Properties::Font;
    has CSS::Properties::Font $.font is rw handles <font-size measure units em ex viewport-width viewport-height>;
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
        $!font //= CSS::Properties::Font.new: :$!css;
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
                   #| absolute positions
                   my Str $box = ~$0;
                   my UInt \edge = %( :top(Top), :right(Right), :bottom(Bottom), :left(Left) ){$1};
                   ( method { self."$box"()[edge] }, );
               }
               when /^ (padding|border|margin)'-'(width|height) $/ {
                   #| cumulative widths and heights
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
