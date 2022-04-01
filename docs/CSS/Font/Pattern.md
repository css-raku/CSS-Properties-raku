[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font)
 :: [Pattern](https://css-raku.github.io/CSS-Properties-raku/CSS/Font/Pattern)

class CSS::Font::Pattern
------------------------

Implements CSS Font Patterns and Matching

Synopsis
--------

```raku
my CSS::Font $font .= new: :font-props("italic bold condensed 10pt/12pt times-roman);
my CSS::Stylesheet:D $css .= parse('style.css'.IO.slurp);
my CSS::Font::Descriptor @font-face = $css.font-face;
my CSS::Font::Pattern $patt = $font.pattern;
my  CSS::Font::Descriptor @matches = $patt.match(@font-face);
say @matches.first.Str;
```

Description
-----------

Implements CSS font matching for a font against CSS::Font::Descriptor `@font-face` rules.

See [Font Matching Algorithm](https://www.w3.org/TR/2018/REC-css-fonts-3-20180920/#font-matching-algorithm)

Methods
-------

### match

```raku
method match(CSS::Font::Descriptor @font-face) returns Array[CSS::Font::Descriptor]
```

Reduces a list of font descriptors to matching fonts, ordered by preference.

