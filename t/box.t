use v6;
use Test;
plan 20;

use CSS::Declarations;
use CSS::Declarations::Units :pt;
use CSS::Declarations::Box;

my $css = CSS::Declarations.new;

$css.padding = 5pt;
$css.border-width = 3pt;
$css.margin = [1pt, 2pt, 3pt, 4pt];

my $top    = 80e0pt;
my $right  = 50e0pt;
my $bottom = 0e0pt;
my $left   = 0e0pt;

my $box = CSS::Declarations::Box.new( :$top, :$left, :$bottom, :$right, :$css );

is-deeply $box.Array, [$top, $right, $bottom, $left], '.Array';
is $box.padding, [$top+5, $right+5, $bottom-5, $left-5], '.padding';
is $box.border, [$top+8, $right+8, $bottom-8, $left-8], '.border';
is $box.margin, [$top+9, $right+10, $bottom-11, $left-12], '.margin';
is $box.width, $right - $left, '.width';
is $box.height, $top - $bottom, '.height';
is $box.width('padding'), $right - $left + 10, '.width("padding")';
is $box.height('padding'), $top - $bottom + 10, '.height("padding")';

is-deeply $box.padding, [$box.padding-top, $box.padding-right, $box.padding-bottom, $box.padding-left], '.padding-XXX';
is-deeply $box.border, [$box.border-top, $box.border-right, $box.border-bottom, $box.border-left], '.border-XXX';
is-deeply $box.margin, [$box.margin-top, $box.margin-right, $box.margin-bottom, $box.margin-left], '.margin-XXX';

is-approx $box.border-width, ($box.border-right - $box.border-left), '.border-width';
is-approx $box.border-height, ($box.border-top - $box.border-bottom), '.border-height';

$box.translate(5, 10);
is-deeply $box.Array, [$top+10, $right+5, $bottom+10, $left+5], '.translate';
is $box.padding, [$top+15, $right+10, $bottom+5, $left], 'translate padding';

$box.move($right-5, $top-10);
is-deeply $box.Array, [$top-10, $right-5, $bottom-10, $left-5], '.move';
is $box.padding, [$top-5, $right, $bottom-15, $left-10], 'move padding';

$box.top += 5;
is-deeply $box.Array, [$top-5, $right-5, $bottom-10, $left-5], '.resize';

dies-ok { note CSS::Declarations::Box.new( :$top, :$left, :bottom($top+1), :$right, :$css )}, 'illegal initial size';

dies-ok { $box.top = $box.bottom -5}, 'illegal resize';

done-testing;
