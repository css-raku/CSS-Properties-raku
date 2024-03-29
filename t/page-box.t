use v6;
use Test;
plan 19;

use CSS::Properties;
use CSS::PageBox;
use CSS::Units :pt, :mm, :ops, :Lengths;

sub mm(CSS::Box::Rect:D $_) { [.Array.map: { ($_ * pt / mm).round }] }
sub pt(CSS::Box::Rect:D $_) { [.Array.map: { .round }] }

my $css = CSS::Properties.new: :style("size: 200pt 300pt");
my CSS::PageBox $box .= new( :$css );

is $box.units, 'pt';
is-deeply $box.Array, [298e0, 198e0, 2e0, 2e0], '.Array';

$css.border = 0pt;

is-deeply $box.new(:$css).Array, [300e0, 200e0, 0e0, 0e0], '.Array';

$css.margin = 3mm;
$css.border-width = 2mm;
$css.padding = 5mm;
$css.size = 'a4';
is $css.Str, "border:2mm; margin:3mm; padding:5mm; size:a4;", "css";
$box .= new(:$css, :units<mm>);

is-deeply mm($box.margin), [297, 210, 0, 0], '.margin (mm)';
is-deeply pt($box.margin), [842, 595, 0, 0], '.margin (pt)';
is-deeply mm($box.border), [294, 207, 3, 3], '.border';
is-deeply mm($box.padding), [292, 205, 5, 5], '.padding';
is-deeply mm($box.content), [287, 200, 10, 10], '.content';

$css .= new: :style("size: auto");
$box .= new(:$css);

is-deeply pt($box.margin), [842, 595, 0, 0], '.margin auto';
is-deeply pt($box.border), [842, 595, 0, 0], '.border auto';
is-deeply pt($box.padding), [840, 593, 2, 2], '.padding auto';
is-deeply pt($box.content), [840, 593, 2, 2], '.content auto';

$css.padding = 2mm;
$css.margin = 3mm;
$box .= new: :$css, :width(200mm), :height(250mm);

is-deeply mm($box.margin), [250, 200, 0, 0], '.margin auto';
is-deeply mm($box.border), [247, 197, 3, 3], '.border auto';
is-deeply mm($box.padding), [246, 196, 4, 4], '.padding auto';
is-deeply mm($box.content), [244, 194, 6, 6], '.content auto (mm)';
is-deeply pt($box.content), [692, 551, 16, 16], '.content auto (pt)';

$css .= new: :style("size:auto; min-width:200pt; max-height:250pt;");
$box .= new( :$css );

is-deeply pt($box.content), [248, 593, 2, 2], 'auto/min/max';

done-testing;
