class CSS::Properties::Context {
    use CSS::Units :Lengths, :&dimension, :pt;

    has $.css is required;
    has Str $.units = 'pt';
    has Numeric $!scale = Lengths.enums{$!units};
    has Numeric $.em is rw = 12pt.scale($!units);
    method ex { $!em * 3/4 }
    has Numeric $.viewport-width;
    has Numeric $.viewport-height;

    subset FontWeight of Numeric where { 100 <= $_ <= 900 && $_ %% 100 }

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

    multi method measure(:line-height($_)!) {
        given (.isa(Bool) ?? $!css.line-height !! $_) {
            when .type eq 'num' { CSS::Units.value($_ * $!em, $!units) }
            when 'normal' { CSS::Units.value($!em * 1.2, $!units) }
            default { $.measure(:font-size($_)); }
        }
    }
    multi method measure(:font-weight($_)!) {
        my $v = .isa(Bool) ?? $!css.font-weight !! $_;
        self!weigh($v);
    }
    my constant %FontSizes = %(
        :xx-small(6pt), :x-small(7.5pt), :small(10pt), :medium(12pt),
        :large(13.5pt), :x-large(18pt), :xx-large(24pt)
    );

    multi method measure(:font-size($_)!) {
        when Bool     {  CSS::Units.value($!em, $!units) }
        when  %FontSizes{$_}:exists {  %FontSizes{$_}.scale: $!units }
        default { $.measure($_, :ref($!em)) }
    }
    multi method measure(:letter-spacing($_)!) {
        given .isa(Bool) ?? $!css.letter-spacing !! $_ {
            when .?type ~~ 'num'  { $_ * $!em }
            when 'normal' { 0.0 }
            default { $.measure: :font-size($_) }
        }
    }
    multi method measure(:word-spacing($_)!) {
        given .isa(Bool) ?? $!css.word-spacing !! $_ {
            when 'normal' { $!em }
            default { $.measure: $_ }
        }
    }
    multi method measure(*%misc where .elems == 1) {
        my ($prop, $value) = %misc.kv;
        given $value {
            my $v = .isa(Bool) ?? $!css."$prop"() !! $_;
            $.measure($v);
        }
    }

    multi method measure(Numeric $v,
                         Numeric :$em = $!em,
                         Numeric :$ex = $.ex,
                         Numeric :$ref = $!em,
                  ) {
        my Str $units = $v.?type // $!units;
        my Numeric $scale = do given $units {
            when 'em'   { $em }
            when 'ex'   { $ex }
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
            when 'larger'   { $v := $!em * 1.2 }
            when 'smaller'  { $v := $!em / 1.2 }
        }

        with $v {
            CSS::Units.value($_, $!units);
        }
        else {
            Nil;
        }
    }
    multi method measure($_) { $_ }

    multi method computed('font-size') {
        self.measure: :font-size;
    }
    multi method computed('font-weight') {
        self.measure: :font-weight;
    }
    multi method computed(Str $prop) {
        my $v := $!css."$prop"();
        with self.measure($v) {
            $_;
        }
        else {
            $v;
        }
    }

}
