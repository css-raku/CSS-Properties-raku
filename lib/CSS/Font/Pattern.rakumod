#| Implements CSS Font Patterns and Matching
unit class CSS::Font::Pattern;
=para See L<Font Matching Algorithm|https://www.w3.org/TR/2018/REC-css-fonts-3-20180920/#font-matching-algorithm>

has Str:D @.family is required;
has Str:D $.style is required;
has Int:D $.weight is required;
has Int:D $.stretch is required;
method Hash { %( :@!family, :$!style, :$!weight, :$!stretch) }

multi method match-stretch([], $) {[]}
multi method match-stretch(@fonts) {
    @fonts.grep({.pattern.stretch == $!stretch})
        || [ @fonts.sort({abs(.pattern.stretch - $!stretch)}) ];
}

multi method match-style([], $) {[]}
multi method match-style(@fonts) {
    my %s = @fonts.classify: { .pattern.style }
    my Array $p = do given $!style {
        when 'italic'  { %s{$_} || %s<oblique>  || %s<normal> || []}
        when 'oblique' { %s{$_} || %s<italic>   || %s<normal> || []}
        when 'normal'  { %s{$_} || %s<oblique>  || %s<italic> || []}
        default { warn "unknown font style: {.raku}"; [] }
    };
    $p.List;
}

multi method match-weight([], $) {[]}
multi method match-weight(@fonts) {
    match-weight(@fonts, $!weight);
}

sub match-weight(@fonts, $weight) {
    @fonts.grep({.pattern.weight == $weight}) || nearest-weight(@fonts, $weight);
}

sub nearest-weight(@fonts, Int:D $w!) {
    when $w < 400 {
        @fonts.grep({.pattern.weight < $w}).sort.reverse;
    }
    when $w > 500 {
        @fonts.grep({.pattern.weight > $w}).sort;
    }
    when $w == 400 {
        @fonts.grep({.pattern.weight == 500}) || match-weight(@fonts, 300);
    }
    when $w == 500 {
        @fonts.grep({.pattern.weight == 400}) || match-weight(@fonts, 300);
    }
}

method match-family(@fonts --> Seq) {
    @fonts.grep: {
        my $family := .font-family.lc;
        @!family.first: {$family eq .lc}
    }
}

method match(@fonts is copy --> Array) {
    for <family stretch style weight> {
        @fonts = self."match-{$_}"(@fonts)
    }
    @fonts;
}
