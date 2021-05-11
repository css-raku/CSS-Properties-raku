[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [Units](https://css-raku.github.io/CSS-Properties-raku/Units)



utility definitions and operators for handing CSS Units

### Snyposis

```raku
use CSS::Units :ops, :pt, :px, :in, :mm;
my $css = (require CSS::Properties).new: :margin[5pt, 10px, .1in, 2mm];
```

### Methods

### multi sub infix:<+css>

```raku
multi sub infix:<+css>(
    CSS::Units $v,
    CSS::Units $n
) returns Mu
```

explicit add

### multi sub infix:<-css>

```raku
multi sub infix:<-css>(
    CSS::Units $v,
    CSS::Units $n
) returns Mu
```

explicit subtract

