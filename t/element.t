use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Element;

my $css = CSS::Declarations.new;
# a bit painful at this early stage
$css.padding-top = $css.padding-right = $css.padding-bottom = $css.padding-left = 5;
$css.border-top = $css.border-right = $css.border-bottom = $css.border-left = 3;
$css.margin-top = 1; $css.margin-right = 2; $css.margin-bottom = 3; $css.margin-left = 4;

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
