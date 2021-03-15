class CSS::Properties::Calculator {
    use CSS::Units :Lengths, :&dimension, :pt;

    has $.css is required;
    has Str $.units = 'pt';
    has Numeric $!scale = Lengths.enums{$!units};
    has Numeric $.em is rw = 12pt.scale($!units);
    method ex { $!em * 3/4 }
    has Numeric $.viewport-width;
    has Numeric $.viewport-height;
    has Numeric $.reference-width is rw = 0;

    subset FontWeight of Numeric where { 100 <= $_ <= 900 && $_ %% 100 }

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
            when .?type ~~ 'num'  { self!em: $_ * $!em; }
            when 'normal' { self!em: 0.0 }
            default { %Compute<font-size>(self, $_) }
        },
        line-height => method ($_) {
            when .type eq 'num' { self!em: $!em * $_  }
            when 'normal'       { self!em: $!em * 1.2 }
            default { %Compute<font-size>(self, $_) }
        },
        word-spacing => method ($_) {
            when 'normal' { self!em }
            default { self.measure: $_, :ref($!em) }
        },
        'border-top-width'|'border-right-width'|'border-bottom-width'|'border-left-width' => method ($_) {
            self.measure($_, :ref(0)); # percentage quantities are ignored
        },
        'width'|'height'|'min-width'|'max-width'|'min-height'|'max-height' => method ($_) {
            self.measure($_, :ref($!reference-width));
        },
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
    multi method measure(*%misc where .elems == 1) {
        my ($prop, $value) = %misc.kv;
        given $value {
            my $v = .isa(Bool) ?? $!css."$prop"() !! $_;
            with %Compute{$prop} {
                .(self, $v);
            }
            else {
                $.measure($v);
            }
        }
    }

    multi method measure(Numeric $v,
                         Numeric :$ref = $!em,
                         :$em, :$ex
                  ) {
        my Str $units = $v.?type // $!units;
        warn 'deprecated measure: :$em' with $em;
        warn 'deprecated measure: :$ex' with $ex;
        my Numeric $scale = do given $units {
            when 'em'   { $!em }
            when 'ex'   { $.ex }
            when 'vw'   { $!viewport-width }
            when 'vh'   { $!viewport-height }
            when 'vmin' { min($!viewport-width, $!viewport-height) }
            when 'vmax' { max($!viewport-width, $!viewport-height) }
            when 'percent' {
                $ref * $!scale / 100;
            }
            default { dimension($_).enums{$_} }
        } // die "unknown units: $units";
        if $scale.defined  {
            CSS::Units.value($v * $scale / $!scale, $!units);
        }
        else {
            Nil;
        }
    }
    multi method measure(Str $_) {
        my $v;

        if .?type ~~ 'keyw' {
            when 'thin'     { $v := 1pt.scale: $!units }
            when 'medium'   { $v := 2pt.scale: $!units }
            when 'thick'    { $v := 3pt.scale: $!units }
        }

        with $v {
            CSS::Units.value($_, $!units);
        }
        else {
            Nil;
        }
    }
    multi method measure($_) { $_ }

    method computed(Str $prop) {
        self.measure: |($prop => True);
    }

}
