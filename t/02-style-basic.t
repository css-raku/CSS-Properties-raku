use v6;
use Test;
plan 15;

use CSS::Properties;

my CSS::Properties $css .= new: :style("color: orange; text-align: center!important; margin: 2pt; border-width: 1px 2px 3pt");

is $css.color, '#FFA500';
is $css.color.type, 'rgb';
is $css.text-align, "center";
is $css.margin, [2 xx 4];
is $css.margin-top, 2;
is $css.margin-top.type, 'pt';
is $css.border-width, [1, 2, 3, 2];

ok $css.important("text-align"), "important property";
nok $css.important("color"), "unimportant property";

$css = CSS::Properties.new: :style("border: 2.5px");
is $css.border-width, [2.5 xx 4];

$css .= new: :style("margin: 2px; margin-bottom: 1px;");
is $css.margin, [2, 2, 1, 2];

$css .= new: :style("border: 2px; border-bottom: 1px;");
is $css.border-width, [2, 2, 1, 2];

$css .= new: :style("background-position: 0 50%;");
is $css.Str, "background:0 50%;";

$css .= new: :style("border-style: solid; border-bottom-style: none;");
is $css.Str, "border-left:solid; border-right:solid; border-top:solid;";
is $css.Str(:keep-defaults), "border-style:solid solid none;";

done-testing;
