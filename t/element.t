use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Element;

my $css = CSS::Declarations.new;

$css.padding = 5;
$css.border-width = 3;
$css.margin = [1,2,3,4];

my $top    = 80;
my $right  = 50;
my $bottom = 0;
my $left   = 0;

my $element = CSS::Declarations::Element.new( :$top, :$left, :$bottom, :$right, :$css);

is-deeply $element.Array, [$top, $right, $bottom, $left];
is-deeply $element.padding, [$top+5, $right+5, $bottom-5, $left-5];
is-deeply $element.border, [$top+8, $right+8, $bottom-8, $left-8];
is-deeply $element.margin, [$top+9, $right+10, $bottom-11, $left-12];

done-testing;
