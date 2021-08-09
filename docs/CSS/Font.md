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
method fontconfig-pattern() returns Mu
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
    Str $patt = Code.new
) returns Str
```

Return a path to a matching system font

Actually calls `fc-match` on `$.font-config-patterm()`

### method match

```raku
method match(
    @font-face,
    :$module = Code.new
) returns CSS::Properties
```

Select matching @font-face font

This method matches a list of `@font-face` properties against the font to select the best match, using the [Font Matching Algorithm](https://www.w3.org/TR/2018/REC-css-fonts-3-20180920/#font-matching-algorithm). Example:

```raku
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
say $font.match($css.font-face); # font-family:'serif'; src:url('/myfonts/serif.otf');
```

