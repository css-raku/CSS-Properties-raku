use v6;
use Test;
plan 15;

use CSS::Properties;
use CSS::Properties::Units :pt, :mm;
use CSS::Properties::PageBox;

my $css = CSS::Properties.new: :style("size: a4");

my CSS::Properties::PageBox $box .= new( :$css );

is-deeply $box.Array, [295e0, 208e0, 2e0, 2e0], '.Array';

$css.border = 0pt;

is-deeply $box.new(:$css).Array, [297e0, 210e0, 0e0, 0e0], '.Array';

$css.margin = 3pt;
$css.border-width = 2pt;
$css.padding = 5pt;
is $css.Str, "border-width:2pt; margin:3pt; padding:5pt; size:a4;", "css";
$box .= new(:$css);

is-deeply $box.margin, [297e0, 210e0, 0e0, 0e0], '.margin';
is-deeply $box.border, [294e0, 207e0, 3e0, 3e0], '.border';
is-deeply $box.padding, [292e0, 205e0, 5e0, 5e0], '.padding';
is-deeply $box.content, [287e0, 200e0, 10e0, 10e0], '.content';

$css .= new: :style("size: auto");
$box .= new(:$css);

is-deeply $box.margin, [842e0, 595e0, 0e0, 0e0], '.margin auto';
is-deeply $box.border, [842e0, 595e0, 0e0, 0e0], '.border auto ';
is-deeply $box.padding, [840e0, 593e0, 2e0, 2e0], '.padding auto ';
is-deeply $box.content, [840e0, 593e0, 2e0, 2e0], '.content auto ';

$box .= new: :$css, :width(200), :height(250);

is-deeply $box.margin, [250e0, 200e0, 0e0, 0e0], '.margin auto';
is-deeply $box.border, [250e0, 200e0, 0e0, 0e0], '.border auto ';
is-deeply $box.padding, [248e0, 198e0, 2e0, 2e0], '.padding auto ';
is-deeply $box.content, [248e0, 198e0, 2e0, 2e0], '.content auto ';


done-testing;
