use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Property;
use CSS::Declarations::Box;

my %properties = %CSS::Declarations::properties;

isa-ok %properties<margin>, CSS::Declarations::Box, 'box property';
isa-ok %properties<margin-left>, CSS::Declarations::Property, 'simple property';

my $css = CSS::Declarations.new;
is $css.azimuth, 'center', 'default azimuth';
is-deeply $css.background-position, [0, 0], 'default background position';
is-deeply $css.margin, [0, 0, 0, 0], 'default margin';
is $css.margin-left, 0, 'default margin-left';

done-testing;
