use v6;
use CSS::Declarations;
use Test;

my $css = CSS::Declarations.new: :style("color: orange; text-align: center!important;");

warn $css.color.perl;
warn $css.text-align.perl;

ok $css.important("text-align"), "text-aign is important";
ok !$css.important("color"), "color is not important";

done-testing;