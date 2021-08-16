[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Units](https://css-raku.github.io/CSS-Properties-raku/CSS/Units)



utility definitions and operators for handing CSS Units

### Synposis

```raku
use CSS::Units :ops, :pt, :px, :in, :mm;
my $css = (require CSS::Properties).new: :margin[5pt, 10px, .1in, 2mm];
```

Description This module implements the following CSS Units
----------------------------------------------------------

<table class="pod-table">
<thead><tr>
<th>Type</th> <th>Units</th>
</tr></thead>
<tbody>
<tr> <td>Length</td> <td>pt pc px mm cm in em ex vw vh</td> </tr> <tr> <td>Resolution</td> <td>dpi dpcm dpx</td> </tr> <tr> <td>Time</td> <td>s ms</td> </tr> <tr> <td>Frequency</td> <td>hz khz</td> </tr> <tr> <td>Percentage</td> <td>%</td> </tr>
</tbody>
</table>

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

