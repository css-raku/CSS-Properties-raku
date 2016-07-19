use v6;

class CSS::Declarations::Position {
    use CSS::Declarations;
    use CSS::Declarations::Units;
    
    has Units $.units is rw = px;
    has Length $.em = 16px;
    has Length $.ex = 10px;

    has Length $.top    is rw;
    has Length $.right  is rw;
    has Length $.bottom is rw;
    has Length $.left   is rw;
 
    has CSS::Declarations $.css;

    method !dim($_ --> Numeric) {
        when 'em' { $!em }
        when 'ex' { $!ex }
        default   { Units.enums{$_}
                    or die "unknown length unit: $_" }
    }

    method !length(Length $qty) {
        $qty.key eq $.units.key
            ?? $qty
            !! $.units.value * $qty / self!dim($qty.key)
    }

    method !lengths(List $qtys) {
        [ $qtys.map: { self!length($_) } ]
    }

    method padding returns Array {
        $.enclose(self!lengths($.Array), self!lengths($!css.padding));
    }
    method border returns Array {
        $.enclose($.padding, self!lengths($!css.border-width));
    }
    method margin returns Array {
        $.enclose($.border, self!lengths($!css.margin));
    }

    method enclose(List $inner, List $outer) {
        [
         $inner[0] + $outer[0], # top
         $inner[1] + $outer[1], # right
         $inner[2] - $outer[2], # bottom
         $inner[3] - $outer[3], # left
        ]
    }

    method Array is rw {
        Proxy.new(
            FETCH => sub ($) {
                [self.top, self.right, self.bottom, self.left]
            },
            STORE => sub ($,$v is copy) {
                $v = [$v] unless $v.isa(List);
                self.top    = $v[0] // 0;
                self.right  = $v[1] // self.top;
                self.bottom = $v[2] // self.top;
                self.left   = $v[3] // self.right
            });
    }
}
