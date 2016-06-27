use v6;
use CSS::Declarations;
use Test;

my $css = CSS::Declarations.new: :style("color: orange; text-align: center!important; margin: 2pt; border-width: 1px 2px 3pt");

is $css.color, [255, 165, 0];
is $css.color.key, 'rgb';
is $css.text-align, "center";
is $css.margin, [1.5 xx 4];
is $css.margin-top, 1.5;
is $css.border-width, [1.0, 2.0, 2.25, 2.0];

ok $css.important("text-align"), "text-align is important";
ok !$css.important("color"), "color is not important";

$css = CSS::Declarations.new: :style("border: 1px 2px 3pt");
todo "compound declarations";
is $css.border-width, [1.0, 2.0, 2.25, 2.0];

done-testing;
