[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::PageBox](https://css-raku.github.io/CSS-Properties-raku/CSS/PageBox)

class CSS::PageBox
------------------

Outer CSS Page Box

Synopsis
--------

```raku
use CSS::PageBox;
use CSS::Units :mm;
use CSS::Properties;

my $style = q:to"END";
     size:a4 landscape;
     border:2mm;
     margin:3mm;
     padding:5mm;
    END

my CSS::Properties $css .= new: :$style;

my CSS::PageBox $box .= new: :$css, :units<mm>;
say $box.margin;  # [297, 210, 0, 0]
say $box.border;  # [294, 207, 3, 3]
say $box.padding; # [292, 205, 5, 5]
say $box.content; # [287, 200, 10, 10]
```

Description
-----------

[CSS::PageBox](https://css-raku.github.io/CSS-Properties-raku/CSS/PageBox) is a sub-class of [CSS::Box](https://css-raku.github.io/CSS-Properties-raku/CSS/Box). It is capable of interepeting and setting up a page from a `@page` at-rule properties, including `size`, `border`, and `padding` properties.

