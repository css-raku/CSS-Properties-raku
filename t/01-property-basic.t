use v6;
use Test;
plan 13;

use CSS::Properties::Property;
use CSS::Properties::Edges;
use CSS::Properties;
use CSS::Units :pt, :px;

my $sample-prop = CSS::Properties::Property.new( :name<background-image> );

is-deeply $sample-prop.name, 'background-image', '$prop.name';
is-deeply $sample-prop.box, False, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<uri> | none', '$prop.synopsis';
is-deeply $sample-prop.default, "none", '$prop.default';

$sample-prop = CSS::Properties::Edges.new( :name<margin> );

is-deeply $sample-prop.name, 'margin', '$prop.name';
is-deeply $sample-prop.box, True, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<margin-width>{1,4}', '$prop.synopsis';

my $css = CSS::Properties.new: :margin(5pt), :width(4px);
is $css.width, 4px, 'declared property';
is $css.height, 'auto', 'defaulted property';
is $css.write, 'margin:5pt; width:4px;', 'construction';
$css = CSS::Properties.new: :style("margin:5pt; width:4px");
is $css.write, 'margin:5pt; width:4px;', 'construction';

done-testing;
