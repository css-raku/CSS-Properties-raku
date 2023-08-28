use v6;
#| Abstract CSS font object
class CSS::Font {
    use CSS::Font::Pattern;
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
    say $font.style.fmt;           # italic
    say $font.weight.fmt;          # 700
    say $font.family.fmt;          # times-roman
    say $font.line-height;         # 12pt
    say $font.measure(:font-size); # 10pt
    say $font.fontconfig-pattern.raku;
    # {:family($("times-roman",)), :slant("italic"), :weight("bold")}

    # requires FontConfig module to be installed
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
    has CSS::Properties $.css handles <font-family em ex measure units viewport-width viewport-height module ast Str>;
    method css is rw {
        Proxy.new(
            FETCH => sub ($) { $!css },
            STORE => sub ($, $!css) { self.setup },
        );
    }

    submethod TWEAK(Str :$font-style, Str :$font-props, |c) {
        $_ .= new(|c) without $!css;
        with $font-style {
            warn 'CSS::Properties::Font.new(:$font-style) is deprecated. Please use :$font-props';
            self.font-props = $_;
        }
        self.font-props = $_ with $font-props;
        self.setup;
    }

    multi method COERCE(Str:D $font-props) {
        self.new: :$font-props;
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

    #| compute a fontconfig pattern for the font
    method fontconfig-pattern(@faces = [] --> Hash) {
        my %patt;
        %patt<family> = (@faces.Slip, @!family.Slip);

        %patt<slant> = $!style
            unless $!style eq 'normal';

        unless $!weight == 400 {
            my $w = <thin extralight light book regular medium semibold bold extrabold black>[$!weight.substr(0,1)];
                #    000  100        200   300  400     500    600      700  800       900
            %patt<weight> = $w;
        }

        # [ultra|extra][condensed|expanded]
        %patt<width> = self!fc-stretch()
            unless $!stretch eq 'normal';
        %patt;
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

    method setup {
        @!family = [];
        my $cont = False;
        with $!css.font-family {
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

        $!style = $!css.font-style;
        $!weight = $!css.computed('font-weight');
        $!stretch = $!css.font-stretch;
	self;
    }

    has CSS::Font::Pattern $!pattern;
    multi method pattern handles<match> {
        my $stretch = self!fc-stretch;
        $!pattern //= Pattern.new: :@!family, :$!style, :$!weight, :$stretch;
    }

    multi method pattern(Str:D @faces --> Pattern) {
        my @family = (@faces.Slip, @!family.Slip);
        self.pattern.clone: :@family;
    }

    #| Return a path to a matching system font
    method find-font(%patt = %.fontconfig-pattern,
                     UInt  :$all is copy,
                     UInt  :$best is copy,
                     --> Str) {
         my $FontConfig := try (require ::('FontConfig::Pattern'));
         if $FontConfig === Nil {
             # Try for an older FontConfig version
             $all = Nil;
             $best = Nil;
             $FontConfig = (require ::('FontConfig'));
             CATCH {
                 when X::CompUnit::UnsatisfiedDependency {
                     die 'The find-font() method requires the FontConfig Raku module';
                 }
             }
        }
        my $patt = $FontConfig.new: :$all, :$best, |%patt;
        if $all || $best {
            $patt.match-series(:$all, :$best).map: *.file;
        }
        else {
            $patt.match.file
                || die "unable to resolve font-pattern: {$patt.Str}"
	}
    }
    =para Requires installation of the Raku FontConfig module`

    =begin pod
    =head3 method pattern
    =begin code :lang<raku>
    method pattern(CSS::Font::Descriptor @font-face) returns CSS::Font::Pattern
    =end code
    This method returns a pattern based on the font and a list
    of `@font-face` font descriptor properties.
    Example:
    =begin code :lang<raku>
    use CSS::Font;
    use CSS::Font::Descriptor;
    use CSS::Font::Pattern;
    use CSS::Stylesheet;

    my CSS::Font $font .= new: :font-props("italic bold 10pt/12pt Georgia,serif");
        my $stylesheet = q:to<END>;
        @font-face {
            font-family:'Sans-serif'; src:url('/myfonts/sans-serif.otf');
        }
        @font-face {
            font-family:'Serif'; src:url('/myfonts/serif.otf');
        }
        @font-face {
            font-family:'Serif'; src:url('/myfonts/serif-bold.otf'); font-weight:bold;
        }
        END
    my CSS::Stylesheet:D $css .= parse($stylesheet);
    my CSS::Font::Descriptor @font-face = $css.font-face;
    my CSS::Font::Pattern $pattern = $font.pattern;
    say $pattern.match(@font-face).first.Str; # font-family:'serif'; src:url('/myfonts/serif.otf');
    =end code
    See also the L<CSS::Font::Resources> module, which is able to handle fetching
    of local and remote objects.
    =end pod

    method select(|c) is DEPRECATED<match> { self.match(|c) }
}

