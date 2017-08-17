use v6;

class CSS::Declarations::Box {
    use CSS::Declarations::Units :pt;
    my Int enum Edges is export(:Edges) <Top Right Bottom Left>;
    has Numeric $.top;
    has Numeric $.right;
    has Numeric $.bottom;
    has Numeric $.left = 0;

    has Array $!padding;
    has Array $!border;
    has Array $!margin;

    use CSS::Declarations::Font;
    has CSS::Declarations::Font $.font is rw handles <font-length>;
    has CSS::Declarations $.css;

    has Hash @.save;

    my subset BoundingBox of Str where 'content'|'border'|'margin'|'padding';

    submethod TWEAK(
        Numeric :$width = 595pt,
        Numeric :$height = 842pt,
        Numeric :$!top = $height,
        Numeric :$!bottom = $!top - $height,
        Numeric :$!right = $!left + $width,
        Str :$style = '',
        Numeric :$em = 12pt,
        Numeric :$ex = 0.75 * $em,
    ) {
        $!css //= CSS::Declarations.new(:$style),
        $!font //= CSS::Declarations::Font.new: :$em, :$ex, :$!css;
        self!resize;
    }

    method !resize {
        die "left > right" if $!left > $!right;
        die "bottom > top" if $!bottom > $!top;
        $!padding = Nil;
        $!border = Nil;
        $!margin = Nil;
    }

    multi method top {
        Proxy.new(
            FETCH => sub ($) { $!top },
            STORE => sub ($, $!top) { self!resize },
            );
    }

    multi method top(BoundingBox $box) {
        self."$box"()[Top];
    }

    multi method right { $!right }
    multi method right(BoundingBox $box) {
        self."$box"()[Right];
    }

    multi method bottom { $!bottom }
    multi method bottom(BoundingBox $box) {
        self."$box"()[Bottom]
    }

    multi method left { $!left }
    multi method left(BoundingBox $box) {
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

    method !length($v) {
        self.font.length($v);
    }

    method !width($qty) {
        { :thin(1pt), :medium(2pt), :thick(3pt) }{$qty} // self!length($qty)
    }

    method widths(List $qtys) {
        [ $qtys.map: { self!width($_) } ]
    }

    method padding returns Array {
        $!padding //= self!enclose($.Array, self.widths($!css.padding));
    }
    method border returns Array {
        $!border //= self!enclose($.padding, self.widths($!css.border-width));
    }
    method margin returns Array {
        $!margin //= self!enclose($.border, self.widths($!css.margin));
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

    method css-height($css = $!css) {
        my Numeric $height = $_ with self!length($css.height);
        with self!length($css.max-height) {
            $height = $_
                if $height.defined && $height > $_;
        }
        with self!length($css.min-height) {
            $height = $_
                if $height.defined && $height < $_;
        }
        $height;
    }

    method css-width($css = $!css) {
        my Numeric $width = $_ with self!length($css.width);
        with self!length($css.max-width) {
            $width = $_
                if !$width.defined || $width > $_;
        }
        with self!length($css.min-width) {
            $width = $_
                if $width.defined && $width < $_;
        }
        $width;
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

    method move( \x = 0, \y = 0) {
        self.Array = [y, x ];
    }

    method translate( \x = 0, \y = 0) {
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
       my @meth = callsame;
       unless @meth {
           given name {
               when /^ (padding|border|margin)'-'(top|right|bottom|left) $/ {
                   #| absolute positions
                   my Str $box = ~$0;
                   my UInt \edge = %( :top(Top), :right(Right), :bottom(Bottom), :left(Left) ){$1};
                   @meth.push: method { self."$box"()[edge] };
               }
               when /^ (padding|border|margin)'-'(width|height) $/ {
                   #| cumulative widths and heights
                   my Str $box = ~$0;
                   @meth.push: do given ~$1 {
                       when 'width'  { method { .[Right] - .[Left] with self."$box"() } }
                       when 'height' { method { .[Top] - .[Bottom] with self."$box"() } }
                   }
               }
           }
           self.^add_method(name, $_) with @meth[0];
       }
       @meth;
    }
    method dispatch:<.?>(\name, |c) is raw {
        self.can(name) ?? self."{name}"(|c) !! Nil
    }
    method FALLBACK(Str \name, |c) {
        self.can(name)
            ?? self."{name}"(|c)
            !! die die X::Method::NotFound.new( :method(name), :typename(self.^name) );
    }
}
