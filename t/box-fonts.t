use v6;
use Test;
plan 19;

use CSS::Properties;
use CSS::Properties::Font;
use CSS::Units :px, :percent;
sub keyw($v) { CSS::Units.value($v, 'keyw') }
my $font-style = 'italic bold 10pt/12pt times-roman';
my $font = CSS::Properties::Font.new: :$font-style;
is $font.em, 10, 'em';
is $font.ex, 7.5, 'ex';
is $font.style, 'italic', 'font-style';
is $font.weight, '700', 'font-weight';
is $font.family, 'times-roman', 'font-family';
is $font.line-height, 12, 'line-height';
is $font.units, 'pt', 'measuring unit';
is $font.measure(:font-size), 10;
is $font.measure(:line-height), 12;
is $font.measure(:font-weight), 700;
is $font.measure(15px), 11.25, 'measure numeric';
is $font.measure(:font-size(120%)), 12, 'measure percentage font-size';
is $font.measure(:font-size(80%)), 8, 'measure percentage font-size';
is $font.measure(:font-size(0%)), 0, 'measure percentage font-size';
is $font.measure(:font-size(keyw('medium'))), 12, 'measure named font-size';
is $font.measure(:font-size(keyw('smaller'))), 10/1.2, 'measure named font-size';
is $font.fontconfig-pattern, 'times-roman:slant=italic:weight=bold', 'fontconfig-pattern';
is $font.Str, "font:{$font-style};", '$font.Str';

is CSS::Properties::Font.new( :font-style("500 condensed 12px/30px Georgia, serif, Times") ).fontconfig-pattern, 'Georgia serif,Times:weight=medium:width=condensed', 'fontconfig-pattern';

done-testing;
