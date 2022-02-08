[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font)

class CSS::Font
---------------

Abstract CSS font object

Synopsis
--------

```raku
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
```

Description
-----------

[CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font) is utility class for managing font related properties and computing fontconfig patterns.

### method fontconfig-pattern

```raku
method fontconfig-pattern(
    @faces = Code.new
) returns Hash
```

compute a fontconfig pattern for the font

### method font-props

```raku
method font-props() returns Mu
```

sets/gets the css font properties as a whole

e.g. `$font.font-css = 'italic bold 10pt/12pt sans-serif';`

### method find-font

```raku
method find-font(
    %patt = Code.new
) returns Str
```

Return a path to a matching system font

Requires installation of the Raku FontConfig module`

### method pattern

```raku
method pattern(CSS::Font::Descriptor @font-face) returns CSS::Font::Pattern
```

This method returns a pattern based on the font and a list of `@font-face` font descriptor properties. Example:

```raku
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
```

See also the [CSS::Font::Resources](https://css-raku.github.io/CSS-Font-Resources-raku/CSS/Font/Resources) module, which is able to handle fetching of local and remote objects.

