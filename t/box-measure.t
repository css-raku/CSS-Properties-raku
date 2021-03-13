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

$css.reference-width = 80;
my $pw := $css.reference-width/10;

my %sides = :top(80pt), :right(50pt), :bottom(0pt), :left(0pt);
my CSS::Box $box .= new: :$css, |%sides;

is-deeply $box.Array, [%sides<top>, %sides<right>, %sides<bottom>, %sides<left>], '.Array';
is $box.padding, [%sides<top>+$pw, %sides<right>+$pw, %sides<bottom>-$pw, %sides<left>-$pw], '.padding';
is $box.border, [%sides<top>+3+$pw, %sides<right>+3+$pw, %sides<bottom>-3-$pw, %sides<left>-3-$pw], '.border';
is $box.margin, [%sides<top>+8+$pw, %sides<right>+8+$pw, %sides<bottom>-8-$pw, %sides<left>-8-$pw], '.margin';
is $box.width, %sides<right> - %sides<left>, '.width';
is $box.height, %sides<top> - %sides<bottom>, '.height';
is $box.width('padding'), %sides<right> - %sides<left> + $pw*2, '.width("padding")';
is $box.height('padding'), %sides<top> - %sides<bottom> + $pw*2, '.height("padding")';

is-deeply $box.padding, [$box.padding-top, $box.padding-right, $box.padding-bottom, $box.padding-left], '.padding-XXX';
is-deeply $box.border, [$box.border-top, $box.border-right, $box.border-bottom, $box.border-left], '.border-XXX';
is-deeply $box.margin, [$box.margin-top, $box.margin-right, $box.margin-bottom, $box.margin-left], '.margin-XXX';

is-approx $box.border-width, ($box.border-right - $box.border-left), '.border-width';
is-approx $box.border-height, ($box.border-top - $box.border-bottom), '.border-height';

done-testing;
