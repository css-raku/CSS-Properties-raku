use v6;
use Test;
use CSS::Declarations;
use CSS::Declarations::Property;
use CSS::Declarations::Edges;
use CSS::Declarations::Units;

my $css = CSS::Declarations.new :border-top-color<red>;
is $css.border-top-color, '#FF0000', ':values constructor';

my $margin-info = $css.info('margin');
isa-ok $margin-info, CSS::Declarations::Edges, 'box property';
is-deeply [$margin-info.edges], ["margin-top", "margin-right", "margin-bottom", "margin-left"], 'edges property';

my $margin-left-info = $css.info('margin-left');
isa-ok $margin-left-info, CSS::Declarations::Property, 'simple property';
is $margin-left-info.edge, 'margin', 'margin-left is a margin edge';

is $css.azimuth, 'center', 'default azimuth';
is $css.background-position, [0, 0], 'default background position';
is $css.margin, [0, 0, 0, 0], 'default margin';
is $css.margin-left, 0, 'default margin-left';

$css.margin-top = 10pt;
is $css.margin-top, 10, 'updated margin-right value';
is $css.margin-top.key, 'pt', 'updated margin-right units';
$css.margin[1] = 20px;
is $css.margin-right.key, 'px', 'updated margin-right units';
is $css.margin, [10, 20, 0, 0], 'updated margin';
$css.border-color = [ :rgb[10,20,30], :color<red> ];
is $css.border-color, <#0A141E red #0A141E red>, 'named and rgb colors';

$css.border-color = 'green';
$css.border-top-color = 'blue';
is $css.border-color, <#0000FF #008000 #008000 #008000>, 'border-color string coercement';

lives-ok { $css.border-top = '1pt dashed blue'}, 'struct str assignment';
my %border-top = $css.border-top;
is +%border-top, 3, 'border top';
is $css.border-top-width, 1pt, 'border top width';
is %border-top<border-top-width>, 1pt, 'border top width';
is %border-top<border-top-style>, 'dashed', 'border top color';
is %border-top<border-top-color>, '#0000FF', 'border top color';
%border-top<border-top-width> = 2pt;
%border-top<border-top-style> = :keyw<dashed>;
lives-ok { $css.border-top = %border-top}, 'struct hash assigment';
%border-top = $css.border-top;
is %border-top<border-top-width>, 2pt, 'border top width';
is %border-top<border-top-style>, 'dashed', 'border top color';
is %border-top<border-top-color>, '#0000FF', 'border top color';
enum Edges <Top Left Bottom Right>;
is $css.border<border-color>[Top], '#0000FF', 'border top color';
dies-ok { $css.info("background"); }, "compound declaration - nyi";

done-testing;
