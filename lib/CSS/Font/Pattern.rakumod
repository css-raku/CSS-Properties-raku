#| Implements CSS Font Patterns and Matching
unit class CSS::Font::Pattern;
=begin pod
=head2 Synopsis
=begin code :lang<raku>
my CSS::Font $font .= new: :font-props("italic bold condensed 10pt/12pt times-roman);
my CSS::Stylesheet:D $css .= parse('style.css'.IO.slurp);
my CSS::Font::Descriptor @font-face = $css.font-face;
my CSS::Font::Pattern $patt = $font.pattern;
my  CSS::Font::Descriptor @matches = $patt.match(@font-face);
say @matches.first.Str;
=end code
=head2 Description
Implements CSS font matching for a font against CSS::Font::Descriptor
`@font-face` rules.

See L<Font Matching Algorithm|https://www.w3.org/TR/2018/REC-css-fonts-3-20180920/#font-matching-algorithm>

=head2 Methods

=head3 match

=begin code :lang<raku>
method match(CSS::Font::Descriptor @font-face) returns Array[CSS::Font::Descriptor]
=end code
Reduces a list of font descriptors to matching fonts, ordered by preference.
=end pod

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
