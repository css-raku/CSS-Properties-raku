use v6;

class CSS::Declarations::Element {
    use CSS::Declarations;
    
    has Numeric $.top    is rw;
    has Numeric $.right  is rw;
    has Numeric $.bottom is rw;
    has Numeric $.left   is rw;
 
    has CSS::Declarations $.css;

    method padding returns Array {
        $.enclose($.Array, $!css.padding);
    }
    method border returns Array {
        $.enclose($.padding, $!css.border);
    }
    method margin returns Array {
        $.enclose($.border, $!css.margin);
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
