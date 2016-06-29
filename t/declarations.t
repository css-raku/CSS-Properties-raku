use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Property;
use CSS::Declarations::Box;
use CSS::Declarations::Units;

my $css = CSS::Declarations.new :style[ :border-top-color<red> ];
is $css.border-top-color, 'red', ':values constructor';

isa-ok $css.property('margin'), CSS::Declarations::Box, 'box property';
isa-ok $css.property('margin-left'), CSS::Declarations::Property, 'simple property';

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

done-testing;
