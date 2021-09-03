use v6;
use Test;
plan 16;

use CSS::Properties::Property;
use CSS::Properties;
use CSS::Units :pt, :px;

my $sample-prop = CSS::Properties::Property.new( :name<background-image> );

is-deeply $sample-prop.name, 'background-image', '$prop.name';
is-deeply $sample-prop.box, False, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<uri> | none', '$prop.synopsis';
is-deeply $sample-prop.default, "none", '$prop.default';

my CSS::Properties::Property %edges = <top right bottom left>.map: {
    $_ => CSS::Properties::Property.new: :name('margin-' ~ $_);
}
dies-ok {CSS::Properties::Property.new( :name<margin> )}, 'missing edges detected';
$sample-prop = CSS::Properties::Property.new( :name<margin>, :%edges );

is-deeply $sample-prop.name, 'margin', '$prop.name';
is-deeply $sample-prop.box, True, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<margin-width>{1,4}', '$prop.synopsis';
is-deeply $sample-prop.top.name, 'margin-top', '$prop.top.name';

my $css = CSS::Properties.new: :margin(5pt), :width(4px);
is $css.width, 4px, 'declared property';
is $css.height, 'auto', 'defaulted property';
is $css.write, 'margin:5pt; width:4px;', 'write';
my $css2 = CSS::Properties.new: :style("margin:7pt; height:5px");
is $css2.write, 'height:5px; margin:7pt;', 'write';

$css2.copy($css);
is $css2.write, 'height:5px; margin:5pt; width:4px;', 'copy/write';

done-testing;
