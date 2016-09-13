use v6;
use Test;
use CSS::Declarations;
use Color;

my $css = CSS::Declarations.new :border-top-color<red>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#FF0000', ':values constructor';
is ~$css, 'border-top-color:red;', 'serialization';

$css = CSS::Declarations.new :border-top-color<rgb(50%,0,0)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#800000', ':values constructor';
is ~$css, 'border-top-color:maroon;', 'serialization';

$css = CSS::Declarations.new :border-top-color<rgba(255,0,0,.5)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#FF0000', ':values constructor';
is ~$css, 'border-top-color:rgba(255, 0, 0, 0.5);', 'serialization';

$css = CSS::Declarations.new :border-top-color<hsl(120,100%,50%)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#00FF00', ':values constructor';
is ~$css, 'border-top-color:hsl(120, 100%, 50%);', 'serialization';

todo "hsla colors";
lives-ok {$css = CSS::Declarations.new :border-top-color<hsla(120,100%,50%,.5)>}, 'hsla';

done-testing;
