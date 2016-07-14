use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Property;
use CSS::Declarations::Edges;
use CSS::Declarations::Units;

my $css = CSS::Declarations.new :style[ :border-top-color<red> ];
is $css.border-top-color, 'red', ':values constructor';

my $margin-info = $css.property('margin');
isa-ok $margin-info, CSS::Declarations::Edges, 'box property';
is-deeply [$margin-info.edges], ["margin-top", "margin-right", "margin-bottom", "margin-left"], 'edges property';

my $margin-left-info = $css.property('margin-left');
isa-ok $margin-left-info, CSS::Declarations::Property, 'simple property';
is $margin-left-info.edge, 'margin', 'margin-left is a margin edge';

is $css.azimuth, 'center', 'default azimuth';
is $css.background-position, [0, 0], 'default background position';
is $css.margin, [0, 0, 0, 0], 'default margin';
is $css.margin-left, 0, 'default margin-left';

$css.margin-top = 10pt;
is $css.margin-top, 10, 'updated margin-right value';
is $css.margin-top.key, 'pt', 'updated margin-right units';
$css.margin[1] = 20px;
is $css.margin-right.key, 'px', 'updated margin-right units';
is $css.margin, [10, 20, 0, 0], 'updated margin';

dies-ok { $css.property("background"); }, "compound declaration - nyi";

done-testing;
