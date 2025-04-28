use v6;
use Test;
plan 18;

use CSS::Properties::PropertyInfo;
use CSS::Properties;
use CSS::Units :pt, :px;
use CSS::Grammar::Test :&json-eqv;

my CSS::Properties::PropertyInfo $sample-prop .= new( :name<background-image> );

is-deeply $sample-prop.name, 'background-image', '$prop.name';
is-deeply $sample-prop.box, False, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<uri> | none', '$prop.synopsis';
is-deeply $sample-prop.default, "none", '$prop.default';

my CSS::Properties::PropertyInfo %edges = <top right bottom left>.map: {
    $_ => CSS::Properties::PropertyInfo.new: :name('margin-' ~ $_);
}
dies-ok {CSS::Properties::PropertyInfo.new( :name<margin> )}, 'missing edges detected';
$sample-prop = CSS::Properties::PropertyInfo.new( :name<margin>, :%edges );

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

cmp-ok $css2.List, &json-eqv, (
    :height(15/4),
    :margin-bottom(5.0),
    :margin-left(5.0),
    :margin-right(5.0),
    :margin-top(5.0),
    :width(3.0)
);

cmp-ok $css2.Hash, &json-eqv, {
    :height(15/4),
    :margin-bottom(5.0),
    :margin-left(5.0),
    :margin-right(5.0),
    :margin-top(5.0),
    :width(3.0)
};

done-testing;
