use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Property;
use CSS::Declarations::Box;

my $css = CSS::Declarations.new;

isa-ok $css.property('margin'), CSS::Declarations::Box, 'box property';
isa-ok $css.property('margin-left'), CSS::Declarations::Property, 'simple property';

is $css.azimuth, 'center', 'default azimuth';
is $css.background-position, [0, 0], 'default background position';
is $css.margin, [0, 0, 0, 0], 'default margin';
is $css.margin-left, 0, 'default margin-left';

$css.margin-top = 10;
$css.margin[1] = 20;
is $css.margin-right, 20, 'updated margin-right';
is $css.margin, [10, 20, 0, 0], 'updated margin';

done-testing;
