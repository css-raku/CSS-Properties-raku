use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Property;
use CSS::Declarations::Box;

my %properties = %CSS::Declarations::properties;

isa-ok %properties<margin>, CSS::Declarations::Box, 'box property';
isa-ok %properties<margin-left>, CSS::Declarations::Property, 'simple property';

done-testing;
