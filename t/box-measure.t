use v6;
use Test;
plan 19;

use CSS::Properties;
use CSS::Units :pt, :percent;
use CSS::Box;

my CSS::Properties $css .= new;

$css.padding = 10%;
$css.border-width = 3pt;
$css.margin = 5pt;

$css.reference-width = 80;
my $pw := $css.reference-width/10;

my %sides = :top(80), :right(50), :bottom(0), :left(0);
my CSS::Box $box .= new: :$css, |%sides;
is $box.units, 'pt', 'default units';
is-deeply $box.Array, [%sides<top>+0e0, %sides<right>+0e0, %sides<bottom>+0e0, %sides<left>+0e0], '.Array';
is $box.padding.Array, [%sides<top>+$pw, %sides<right>+$pw, %sides<bottom>-$pw, %sides<left>-$pw], '.padding';
is $box.border.Array, [%sides<top>+3+$pw, %sides<right>+3+$pw, %sides<bottom>-3-$pw, %sides<left>-3-$pw], '.border';
is $box.margin.Array, [%sides<top>+8+$pw, %sides<right>+8+$pw, %sides<bottom>-8-$pw, %sides<left>-8-$pw], '.margin';
is $box.width, %sides<right> - %sides<left>, '.width';
is $box.height, %sides<top> - %sides<bottom>, '.height';
is $box.width('padding'), %sides<right> - %sides<left> + $pw*2, '.width("padding")';
is $box.height('padding'), %sides<top> - %sides<bottom> + $pw*2, '.height("padding")';

is-deeply $box.padding.Array, [$box.padding-top, $box.padding-right, $box.padding-bottom, $box.padding-left], '.padding-XXX';
is-deeply $box.border.Array, [$box.border-top, $box.border-right, $box.border-bottom, $box.border-left], '.border-XXX';
is-deeply $box.margin.Array, [$box.margin-top, $box.margin-right, $box.margin-bottom, $box.margin-left], '.margin-XXX';

is-approx $box.border-width, ($box.border-right - $box.border-left), '.border-width';
is-approx $box.border-height, ($box.border-top - $box.border-bottom), '.border-height';

$css .= clone: :units<px>;
is $css.units, 'px';
$box .= new: :$css, |%sides;
is $box.units, 'px', 'changed units';
is-deeply $box.Array, [%sides<top>+0e0, %sides<right>+0e0, %sides<bottom>+0e0, %sides<left>+0e0], '.Array';

# padding is a percentage adjustment, so does not change
is $box.padding.Array, [%sides<top>+$pw, %sides<right>+$pw, %sides<bottom>-$pw, %sides<left>-$pw], '.padding';

# padding (10%) + 7pt
my \adj = $pw + $box.measure(8pt);
is-deeply $box.margin.Array.map(*.round(0.001)), (%sides<top>+adj, %sides<right>+adj, %sides<bottom>-adj, %sides<left>-adj).map(*.round(0.001)), 'adjusted .margin';

done-testing;
