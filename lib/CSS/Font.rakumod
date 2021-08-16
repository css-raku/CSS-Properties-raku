use v6;
#| Abstract CSS font object
class CSS::Font {
    use CSS::Properties;
    use CSS::Properties::Calculator :FontWeight;
    use CSS::Units :pt;

    =begin pod
    =head2 Synopsis
    =begin code :lang<raku>
    use CSS::Font;
    my $font-props = 'italic bold 10pt/12pt times-roman';
    my CSS::Font $font .= new: :$font-props;
    say $font.em;                  # 10
    say $font.ex;                  # 7.5
    say $font.style;               # italic
    say $font.weight;              # 700
    say $font.family;              # times-roman
    say $font.line-height;         # 12
    say $font.units;               # pt
    say $font.measure(:font-size); # 10
    say $font.fontconfig-pattern;
    # times-roman:slant=italic:weight=bold

    # requires fontconfig to be installed
    say $font.find-font;
    # /usr/share/fonts/truetype/liberation/LiberationSerif-BoldItalic.ttf
    =end code

    =head2 Description

    =para L<CSS::Font> is utility class for managing font related
    properties and computing fontconfig patterns.

    =end pod

    has FontWeight $.weight is rw = 400;
    has Str @.family;
    has Str $.style = 'normal';
    has Numeric $.line-height;
    has Str $.stretch;
    has CSS::Properties $.css handles <em ex measure units viewport-width viewport-height Str> .= new();
    method css is rw {
        Proxy.new(
            FETCH => sub ($) { $!css },
            STORE => sub ($, $!css) { self.setup },
        );
    }

    submethod TWEAK(Str :$font-style, Str :$font-props) {
        self.font-props = $_ with $font-props;
        self.setup;
    }

   method line-height { $!line-height //= $!css.measure(:line-height); }
   method !fc-stretch {
        my constant %Stretch = %(
            :normal(100),
            :semi-expanded(113), :expanded(125), :extra-expanded(150), :ultra-expanded(200),
            :semi-condensed(87), :condensed(75), :extra-condensed(63), :ultra-condensed(50),
        );

        %Stretch{$!stretch};
    }

    #| Deprecated - see CSS::Font::Loader module
    method fontconfig-pattern is DEPRECATED<CSS::Font::Loader.fontconfig-pattern> {
        my Str $pat = @!family.join: ',';

        $pat ~= ':slant=' ~ $!style
            unless $!style eq 'normal';

        $pat ~= ':weight='
        #    000  100        200   300  400     500    600      700  800       900
          ~ <thin extralight light book regular medium semibold bold extrabold black>[$!weight.substr(0,1)]
            unless $!weight == 400;

        # [ultra|extra][condensed|expanded]
        $pat ~= ':width=' ~ self!fc-stretch()
            unless $!stretch eq 'normal';
        $pat;
    }

    #| sets/gets the css font properties as a whole
    method font-props is rw {
        Proxy.new(
            FETCH => sub ($) { $!css.font },
            STORE => sub ($, Str \font-props) {
                $!css.font = font-props;
                self.setup;
            });
    }
    =para e.g. `$font.font-css = 'italic bold 10pt/12pt sans-serif';`

    method font-style(|c) is rw is DEPRECATED<font-props> { self.font-props(|c) }

    method setup(CSS::Properties $css = $!css) {
        @!family = [];
        my $cont = False;
        with $css.font-family {
            for .list {
                when ',' { $cont = False }
                when $cont && .type eq 'keyw' {
                    @!family.tail ~= ' ' ~ $_;
                }
                default {
                    @!family.push: $_;
                    $cont = True;
                }
            }
        }

        $!style = $css.font-style;
        $!weight = $css.computed('font-weight');
        $!stretch = $css.font-stretch;
	self;
    }

    multi method pattern(CSS::Font:D:) {
        my $stretch = self!fc-stretch;
        %( :@!family, :$!style, :$!weight, :$stretch );
    }

    multi sub match-stretch([], $) {[]}
    multi sub match-stretch(@patterns, Int:D $stretch!) {
        @patterns.grep({.key<stretch> == $stretch})
        || [ @patterns.sort({abs(.key<stretch> - $stretch)}) ];
    }

    multi sub match-style([], $) {[]}
    multi sub match-style(@patterns, Str:D $style) {
        my %s = @patterns.classify: { .key<style> }
        my Array $p = do given $style {
            when 'italic'  { %s{$_} || %s<oblique>  || %s<normal> || []}
            when 'oblique' { %s{$_} || %s<italic>   || %s<normal> || []}
            when 'normal'  { %s{$_} || %s<oblique>  || %s<italic> || []}
            default { warn "unknown font style: {.raku}"; [] }
        };
        $p.List;
    }

    multi sub match-weight([], $) {[]}
    multi sub match-weight(@patterns, Int:D $w!) {
         @patterns.grep({.key<weight> == $w}) || nearest-weight(@patterns, $w)
    }

    sub nearest-weight(@patterns, Int:D $_!) {
        when * < 400 {
            @patterns.grep({.key<weight> < $_}).sort.reverse;
        }
        when * > 500 {
            @patterns.grep({.key<weight> > $_}).sort;
        }
        when 400 {
            @patterns.grep({.key<weight> == 500}) || match-weight(@patterns, 300);
        }
        when 500 {
            @patterns.grep({.key<weight> == 400}) || match-weight(@patterns, 300);
        }
    }

    #| Deprecated - see CSS::Font::Loader module
    method find-font(Str $patt = $.fontconfig-pattern --> Str) is DEPRECATED<CSS::Font::Loader.fontconfig-pattern> {
        my $cmd =  run('fc-match',  '-f', '%{file}', $patt, :out, :err);
        given $cmd.err.slurp {
            note chomp($_) if $_;
        }
        my $file = $cmd.out.slurp;
        $file
          || die "unable to resolve font-pattern: $patt"
    }

    #| Select matching @font-face font
    method match(@font-face, :$module = $.css.module.sub-module<@font-face> --> Array) {
        my %patt = self.pattern;
        my @patterns = @font-face.grep({
            my $family := .font-family.lc;
            @!family.first: {$family eq .lc}
        })
        .map(-> $css {
            my %matching-patt = CSS::Font.new(:$css, :$module).pattern;
            %matching-patt => $css
        });

        @patterns .= &match-stretch(%patt<stretch>);
        @patterns .= &match-style(%patt<style>);
        @patterns .= &match-weight(%patt<weight>);

        @patterns>>.value;
    }
    =begin pod
    This method matches a list of `@font-face` properties against the font
    to select matches, using the L<Font Matching Algorithm|https://www.w3.org/TR/2018/REC-css-fonts-3-20180920/#font-matching-algorithm>.
    Example:
    =begin code :lang<raku>
    use CSS::Font;
    use CSS::Stylesheet;
    my CSS::Font $font .= new: :font-style("italic bold 10pt/12pt Georgia,serif");
    my $stylehseet = q:to<END>;
        @font-face {
          font-family:'Sans-serif'; src:url('/myfonts/sans-serif.otf');
        }
        @font-face {
          font-family:'Serif'; src:url('/myfonts/serif.otf');
        }
    END
    my CSS::Stylesheet $css .= load: :$stylesheet;
    say $font.match($css.font-face).first; # font-family:'serif'; src:url('/myfonts/serif.otf');
    =end code
    =end pod

    method select(|c) is DEPRECATED<match> { self.match(|c) }
}

