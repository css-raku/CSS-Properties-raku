use v6;
use Test;
plan 13;

use CSS::Properties;
use CSS::Units :pt, :percent;
use CSS::Box;

my CSS::Properties $css .= new;

$css.padding = 10%;
$css.border-width = 3pt;
$css.margin = 5pt;

my $top    = 80e0pt;
my $right  = 50e0pt;
my $bottom = 0e0pt;
my $left   = 0e0pt;

my %sides = :top(80pt), :right(50pt), :bottom(0pt), :left(0pt);
my CSS::Box $box .= new: :$css, |%sides;

is-deeply $box.Array, [%sides<top>, %sides<right>, %sides<bottom>, %sides<left>], '.Array';
is $box.padding, [%sides<top>+5, %sides<right>+5, %sides<bottom>-5, %sides<left>-5], '.padding';
is $box.border, [%sides<top>+8, %sides<right>+8, %sides<bottom>-8, %sides<left>-8], '.border';
my $bw := $box.width;
is $box.margin, [%sides<top>+8+$bw/10, %sides<right>+8+$bw/10, %sides<bottom>-8-$bw/10, %sides<left>-8-$bw/10], '.margin';
is $box.width, %sides<right> - %sides<left>, '.width';
is $box.height, %sides<top> - %sides<bottom>, '.height';
is $box.width('padding'), %sides<right> - %sides<left> + 10, '.width("padding")';
is $box.height('padding'), %sides<top> - %sides<bottom> + 10, '.height("padding")';

is-deeply $box.padding, [$box.padding-top, $box.padding-right, $box.padding-bottom, $box.padding-left], '.padding-XXX';
is-deeply $box.border, [$box.border-top, $box.border-right, $box.border-bottom, $box.border-left], '.border-XXX';
is-deeply $box.margin, [$box.margin-top, $box.margin-right, $box.margin-bottom, $box.margin-left], '.margin-XXX';

is-approx $box.border-width, ($box.border-right - $box.border-left), '.border-width';
is-approx $box.border-height, ($box.border-top - $box.border-bottom), '.border-height';

done-testing;
