[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font)

class CSS::Font
---------------

Abstract CSS font object

Synopsis
--------

```raku
use CSS::Font;
my $font-props = 'italic bold 10pt/12pt times-roman';
my $font = CSS::Font.new: :$font-props;
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

=head2 Description

=para L<CSS::Font> is utility class for managing font related
properties and computing fontconfig patterns.
```

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
    Str $name = Code.new
) returns Str
```

Return a path to a matching system font

Actually calls `fc-match` on `$.font-config-patterm()`

