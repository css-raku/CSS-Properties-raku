use v6;
use Test;
use CSS::Declarations::Units;
use CSS::Declarations::Position;

my $css = CSS::Declarations.new;

$css.padding = 5pt;
$css.border-width = 3pt;
$css.margin = [1pt, 2pt, 3pt, 4pt];

my $top    = 80pt;
my $right  = 50pt;
my $bottom = 0pt;
my $left   = 0pt;

my $element = CSS::Declarations::Position.new( :$top, :$left, :$bottom, :$right, :$css, :units(pt));

is-deeply $element.Array, [$top, $right, $bottom, $left];
is-deeply $element.padding, [$top+5, $right+5, $bottom-5, $left-5];
is-deeply $element.border, [$top+8, $right+8, $bottom-8, $left-8];
is-deeply $element.margin, [$top+9, $right+10, $bottom-11, $left-12];

$element.units = Units::px;

is $element.padding, [63.75, 41.25, -3.75, -3.75], 'unit change';

done-testing;
