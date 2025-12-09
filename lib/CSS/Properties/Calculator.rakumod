#| property calculator and measurement tool.
class CSS::Properties::Calculator {
    use CSS::Units :Lengths, :&dimension, :pt;
    use CSS::Properties::Util :&from-ast;

    =begin pod
    =head2 Synopsis
    =begin code :lang<raku>
    use CSS::Properties;
    use CSS::Properties::Calculator;
    my CSS::Properties $css .= new: :style("font:12pt Helvetica;");
    my CSS::Properties::Calculator $calc .= new: :$css, :units<mm>, :veiwport-width<250>;
    # Converts a value to a numeric quantity;
    my Numeric $font-size = $css.measure: :font-size; # get current font size (mm)
    $font-size = $css.measure: :font-size<smaller>;   # compute a smaller font-size
    $font-size = $css.measure: :font-size(120%);      # compute a larger font-size
    $font-size = "calc(1.5rem + 3vw)";                # compute a calculated font-size
    $font-size = $css.measure: :font-size;
    my $weight = $css.measure: :font-weight;          # get current font weight 100..900
    $weight = $css.measure: :font-weight<bold>;       # compute bold font weight
    =end code

    =head2 Description

    This module supports conversion or evaluation of quantities to numerical values.
    =item CSS length quantities may rely on context. For example `ex` depends on the current font and font-size
    =item Furthermore the `measure` method converts lengths to preferred units (by default `pt`).
    =item `font-weight` is converted to a numerical value in the range 100 .. 900
    =item Basic evaluation of L<calc()|https://www.w3.org/TR/css-values-3/#calc-notation> arithmetic expressions in
          property values is supported.

    Note: L<CSS::Properties>, L<CSS::Box> and L<CSS::Font> objects all encapsulate a calculator object which handles `measure` and `calculate` methods.
    =begin code
    my CSS::Properties $css .= new: :style("font:12pt Helvetica;"), :units<mm>, :veiwport-width<250>;
    my Numeric $font-size = $css.measure: :font-size;
    =end code
    =end pod

    has $.css is required;
    has Str $.units = 'pt';
    has Numeric $!scale = Lengths.enums{$!units};
    has Numeric $.em is rw = 12pt.scale($!units);
    has Numeric $!rem = $!em; # original $!em
    method ex { $!em * 3/4 }
    has Numeric $.viewport-width;
    has Numeric $.viewport-height;
    has Numeric $.reference-width;
    has Numeric $.user-width = 1.0;
    method reference-width is rw {
        Proxy.new(
            FETCH => { $!reference-width // 0 },
            STORE => -> $, Numeric:D() $v {
                my $units = $v.?units // $!units;
                $!reference-width = CSS::Units.value($v, $units).scale: $!units;
            }
        );
    }

    subset FontWeight is export(:FontWeight) of Numeric where { 100 <= $_ <= 900 && $_ %% 100 }

    my constant %FontSizes = %(
        :xx-small(6pt), :x-small(7.5pt), :small(10pt), :medium(12pt),
        :large(13.5pt), :x-large(18pt), :xx-large(24pt)
    );

    method !em($v = $!em) { CSS::Units.value: $v, $!units }

    my Method %Compute;
    BEGIN %Compute = (
        font-size => method ($_) {
            when %FontSizes{$_}:exists { %FontSizes{$_}.scale: $!units }
            when 'larger'   { self!em: $!em * 1.2 }
            when 'smaller'  { self!em: $!em / 1.2 }
            default { $.measure($_, :ref($!em)) }
        },
        font-weight => method ($_) {
            self!weigh($_);
        },
        letter-spacing => method ($_) {
            when .?type ~~ 'num'|Any:U  { self!em: $_ * $!em; }
            when 'normal' { self!em: 0.0 }
            default { %Compute<font-size>(self, $_) }
        },
        line-height => method ($_) {
            when 'normal'        { self!em: $!em * 1.2 }
            when .?type ~~ 'num'|Any:U {self!em: $!em * $_  }
            default { %Compute<font-size>(self, $_) }
        },
        word-spacing => method ($_) {
            when 'normal' { self!em }
            default { self.measure: $_, :ref($!em) }
        },
        'border-top-width'|'border-right-width'|'border-bottom-width'|'border-left-width' => method ($_, :$ref = 0) {
            self.measure($_, :$ref); # percentage needs to be supplied
        },
        'width'|'height'|'min-width'|'max-width'|'min-height'|'max-height'|'padding-top'|'padding-right'|'padding-bottom'|'padding-left'|'margin-top'|'margin-right'|'margin-bottom'|'margin-left' => method ($_) {
            self.measure($_, :ref($!reference-width));
        },
        # SVG
        'stroke-width'|'stroke-dasharray' =>  method ($_) {
            when .?type ~~ 'num'|Any:U  { self!em($_ * $!user-width); }
            default { self.measure($_, :ref($!viewport-width)); }
        },
        'fill-opacity'|'opacity'|'stop-opacity'|'stroke-opacity' => method (Numeric:D $v is copy) {
            $v /= 100 if $v.?type ~~ 'percent';
            max(0.0, min($v, 1.0));
        }
    );

    #| converts a weight name to a three digit number:
    #| 100 lightest ... 900 heaviest
    method !weigh($_, Int $delta = 0) returns FontWeight {
        my $v = do given .lc {
            when FontWeight       { .Int }
            when 'normal'         { 400 }
            when 'bold'           { 700 }
            when 'lighter'        { 100 }
            when 'bolder'         { 700 }
            default {
                if /^ <[1..9]>00 $/ {
                    .Int
                }
                else {
                    warn "unhandled font-weight: $_";
                    400;
                }
            }
        };
        $v = min(900, max(100, $v + $delta));
        CSS::Units.value($v, 'int');
    }

    multi method measure(:font-size($_)!) {
        when Bool { CSS::Units.value($!em, $!units) }
        default   { %Compute<font-size>(self, $_) }
    }

    multi method measure(:$ref = 0, *%misc where .elems == 1) {
        my :($prop, $value) := %misc.kv;
        given $value {
            my $v = .isa(Bool) ?? $!css."$prop"() !! $_;
            with %Compute{$prop} {
                .(self, $v, :$ref);
            }
            else {
                given $.measure($v, :$ref) {
                    .isa(List)
                        ??  [ $v.map: {$.measure($_, :$ref)} ]
                        !!  $v;
                }
            }
        }
    }

    # trivial epxression
    multi sub calc( % ( :@expr! ) ) {
        calc |@expr;
    }

    # parenthesized sub-expression
    multi sub calc( % ( :op($)! where '(' ), %expr, % ( :op($)! where ')' ) ) {
        calc %expr;
    }

    # binary left associative arithmetic operation
    multi sub calc( %lhs, % ( :$op! ),  *@rhs (%, *@) ) {
        use CSS::Units :ops; # Use arithmetic operator overloading
        my $v1 := calc(%lhs);
        my $v2 := calc(|@rhs);
        given $op {
            when '+' { $v1 + $v2 }
            when '-' { $v1 - $v2 }
            when '*' { $v1 * $v2 }
            when '/' { $v1 / $v2 }
        }
    }

    # numeric constant
    multi sub calc( % ( Numeric:D :$num! ) ) {
        $num;
    }

    # css quantity
    multi sub calc( %ast ) {
        $*calc.measure: from-ast(%ast), :$*ref;
    }

    multi sub calc( *@expr ) {
        warn "Unhandled expression: {@expr.map(*.raku).join: "|"}";
    }

    multi sub func('calc', @expr) {
        calc |@expr;
    }

    multi sub func($ident, |) {
        warn "Unrecognised function: " ~ $ident;
    }

    sub evaluate(:%func! ( :$ident!, :@expr! )) {
        func $ident, @expr;
    }
    multi method measure($*calc: Pair $expr, Numeric :$*ref = $!em) {
        evaluate |$expr;
    }
    multi method measure(Numeric $v is copy,
                         Numeric :$ref = $!em,
                  ) {
        my Str $units = $v.?type // $!units;

        my Numeric $scale = do given $units {
            when 'none' { $v = Nil }
            when 'em'   { $!em }
            when 'ch'   { $!em * .8 } # todo: should be advance width of '0'
            when 'rem'  { $!rem }
            when 'ex'   { $.ex }
            when 'vw'   { $!viewport-width }
            when 'vh'   { $!viewport-height }
            when 'vmin' { min($!viewport-width, $!viewport-height) }
            when 'vmax' { max($!viewport-width, $!viewport-height) }
            when 'percent' { $ref * $!scale / 100; }
            default     {
                given dimension($_) {
                    when Enumeration { .enums{$units} }
                    default {
                        warn "Unknown units: $units";
                        1;
                    }
                }
            }
        };
        with $scale {
            CSS::Units.value($v * $_ / $!scale, $!units);
        }
        else {
            $v;
        }
    }

    multi method measure(Str $v is copy) {
        my Numeric $n;
        with $v {
            when 'none'   { $v = Nil }
            when 'thin'   { $n := 1pt.scale: $!units }
            when 'medium' { $n := 2pt.scale: $!units }
            when 'thick'  { $n := 3pt.scale: $!units }
        }

        with $n {
            CSS::Units.value($_, $!units);
        }
        else {
            $v;
        }
    }
    multi method measure($_) { $_ }

    method computed(Str $prop) {
        self.measure: |($prop => True);
    }

}
