use v6;
use Test;
plan 13;

use CSS::Properties;
use CSS::Units :pt, :percent;
use CSS::Box;

my CSS::Properties $css .= new;

$css.padding = 5pt;
$css.border-width = 3pt;
$css.margin = 5pt;

my $top    = 80e0pt;
my $right  = 50e0pt;
my $bottom = 0e0pt;
my $left   = 0e0pt;

my %bp = :top(80pt), :right(50pt), :bottom(0pt), :left(0pt);
my CSS::Box $parent .= new: :$css, |%bp;

$css .= clone;
$css.margin = 10%;

my %bc = :top(70pt), :right(60pt), :bottom(10pt), :left(10pt);
my CSS::Box $box .= new: :$css, :$parent, |%bc;

is-deeply $box.Array, [%bc<top>, %bc<right>, %bc<bottom>, %bc<left>], '.Array';
is $box.padding, [%bc<top>+5, %bc<right>+5, %bc<bottom>-5, %bc<left>-5], '.padding';
is $box.border, [%bc<top>+8, %bc<right>+8, %bc<bottom>-8, %bc<left>-8], '.border';
my $pw := $parent.width;
my $ph := $parent.height;
is $box.margin, [%bc<top>+8+$ph/10, %bc<right>+8+$pw/10, %bc<bottom>-8-$ph/10, %bc<left>-8-$pw/10], '.margin';
is $box.width, %bc<right> - %bc<left>, '.width';
is $box.height, %bc<top> - %bc<bottom>, '.height';
is $box.width('padding'), %bc<right> - %bc<left> + 10, '.width("padding")';
is $box.height('padding'), %bc<top> - %bc<bottom> + 10, '.height("padding")';

is-deeply $box.padding, [$box.padding-top, $box.padding-right, $box.padding-bottom, $box.padding-left], '.padding-XXX';
is-deeply $box.border, [$box.border-top, $box.border-right, $box.border-bottom, $box.border-left], '.border-XXX';
is-deeply $box.margin, [$box.margin-top, $box.margin-right, $box.margin-bottom, $box.margin-left], '.margin-XXX';

is-approx $box.border-width, ($box.border-right - $box.border-left), '.border-width';
is-approx $box.border-height, ($box.border-top - $box.border-bottom), '.border-height';

done-testing;
