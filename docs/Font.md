[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [Font](https://css-raku.github.io/CSS-Properties-raku/Font)

class CSS::Font
---------------

Abstract CSS font object

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

