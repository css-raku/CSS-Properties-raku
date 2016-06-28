use v6;
use CSS::Declarations;
use Test;

my $css = CSS::Declarations.new: :style("color: orange; text-align: center!important; margin: 2pt; border-width: 1px 2px 3pt");

is $css.color, [255, 165, 0];
is $css.color.key, 'rgb';
is $css.text-align, "center";
is $css.margin, [2 xx 4];
is $css.margin-top, 2;
is $css.margin-top.key, 'pt';
is $css.border-width, [1, 2, 3, 2];

ok $css.important("text-align"), "text-align is important";
nok $css.important("color"), "color is not important";

$css = CSS::Declarations.new: :style("border: 2.5px");
is $css.border-width, [2.5 xx 4];

done-testing;
