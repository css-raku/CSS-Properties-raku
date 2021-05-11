[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties)
 :: [Property](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Property)

class CSS::Properties::Property
-------------------------------

Meta-data for a given property

Synopsis
--------

```raku
use CSS::Properties::Property;
my CSS::Properties::Property %edges = <top right bottom left>.map: {
    $_ => CSS::Properties::Property.new: :name('margin-' ~ $_);
}
my CSS::Properties::Property $margin-info .= new: :name<margin>, :%edges;
is-deeply $margin-info.name, 'margin', '$prop.name';
say $margin-info.box;      # True
say $margin-info.inherit;  # False
say $margin-info.synopsis; # <margin-width>{1,4}
say $margin-info.top.name, # margin-top
```

Description
-----------

Information class for individual properties

Methods
-------

### new

```raku
 method new(
    Str :$prop-name,   # property name e.g. 'margin-top'
    CSS::Module :$module = CSS::Module::CSS3.new(), 
    CSS::Properties::Property :%edges{ :$top, :$left, :$bottom, :$right},
 ) returns CSS::Properties::Property;
```

Returns a new object containing inforation on the given property

Accessors
---------

The following [CSS::Module::Property](https://css-raku.github.io/CSS-Module-raku) accessors are handled by this object

<table class="pod-table">
<thead><tr>
<th>Name</th> <th>Type</th> <th>Description</th>
</tr></thead>
<tbody>
<tr> <td>name</td> <td>Str</td> <td>Property name, e.g. &#39;top-margin&#39;</td> </tr> <tr> <td>prop-num</td> <td>UInt</td> <td>A unique number for the property</td> </tr> <tr> <td>inherit</td> <td>Bool</td> <td>The property is inherited?</td> </tr> <tr> <td>initial</td> <td>Bool</td> <td>Property should reset to it&#39;s initial value?</td> </tr> <tr> <td>important</td> <td>Bool</td> <td>Property has !important inheritance mode</td> </tr> <tr> <td>synposis</td> <td>Bool</td> <td>Property value L&lt;syntax|http://www.w3.org/TR/CSS21/about.html#property-defs&gt; definition</td> </tr> <tr> <td>default-value</td> <td>Any</td> <td>Default value for the property</td> </tr> <tr> <td>edge-names</td> <td>List</td> <td>top, right, bottom, left components [1]</td> </tr> <tr> <td>child-names</td> <td>List</td> <td>child components [2]</td> </tr>
</tbody>
</table>

Notes:

  * [1] for example `margin` has edge-names `top-margin` ... `left-margin`

  * [2] for example `font` has child-names `family-name`, `font-weight` ...

