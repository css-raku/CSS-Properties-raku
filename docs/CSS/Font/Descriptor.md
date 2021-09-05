[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font)
 :: [Descriptor](https://css-raku.github.io/CSS-Properties-raku/CSS/Font/Descriptor)

class CSS::Font::Descriptor
---------------------------

A @font-face font descriptor rule

### method font-props

```raku
method font-props() returns Mu
```

sets/gets the css font properties as a whole

Synopsis
--------

```raku
use CSS::Font::Descriptor;
my CSS::Font::Descriptor $fd;
$fd .= new: style => q:to<END;
  font-family: "DejaVu Sans";
  src: url("fonts/DejaVuSans.ttf");
  font-variant: small-caps;
  END
# -- or --
$fd .= new: :font-family("DejaVu Sans"),
            :src('url("fonts/DejaVuSans.ttf")'),
            :font-variant<small-caps>;
```

### Description

Objects of this class describe a single `@font-face` font descriptor.

This class is based on [CSS::Font](https://css-raku.github.io/CSS-Properties-raku/CSS/Font) and has all its methods available with the exception of `font-props()`.

