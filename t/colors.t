use v6;
use Test;
plan 33;

use CSS::Properties;
use Color;

my CSS::Properties $css .= new :border-top-color<red>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#FF0000', ':values constructor';
is ~$css, 'border-top:red;', 'serialization';

$css .= new :border-top-color<rgb(127,0,0)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#7F0000', ':values constructor';
is-approx $css.border-top-color.a, 255, ':values constructor';
is ~$css, 'border-top:maroon;', 'serialization';

$css .= new :border-top-color<rgba(50%,0,0,1.0)>;
is-approx $css.border-top-color.a, 255, ':values constructor';

$css .= new :border-top-color<rgba(255,0,0,.5)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#FF0000', ':values constructor';
is-approx $css.border-top-color.a, 128, ':values constructor';
is ~$css, 'border-top:rgba(255, 0, 0, 0.5);', 'serialization';

$css .= new :border-top-color<rgba(255,0,0,50%)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#FF0000', ':values constructor';
is-approx $css.border-top-color.a, 128, ':values constructor';
is ~$css, 'border-top:rgba(255, 0, 0, 0.5);', 'serialization';

$css .= new :border-top-color<hsl(120,100%,50%)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#00FF00', ':values constructor';
is-approx $css.border-top-color.a, 255, ':values constructor';
is ~$css, 'border-top:hsl(120, 100%, 50%);', 'serialization';

$css .= new :border-top-color<hsla(120,100%,50%,.5)>;
isa-ok $css.border-top-color, Color, ':values constructor';
is $css.border-top-color, '#00FF00', ':values constructor';
is-approx $css.border-top-color.a, 128, ':values constructor';
is ~$css, 'border-top:hsla(120, 100%, 50%, 0.5);', 'serialization';

$css .= new :background-color<transparent>;
isa-ok $css.background-color, Color, ':values constructor';
is $css.background-color, '#000000', ':values constructor';
is-approx $css.background-color.a, 0, ':values constructor';
is ~$css, '', 'serialization';

# special handling of border colors. These default to the current color

$css .= new: :color<green>;
is $css.border-top-color, '#008000', 'border-*-color default';
$css.color = 'red';
is $css.border-top-color, '#FF0000', 'border-*-color default';
is $css.border-right-color, '#FF0000', 'border-*-color default';

$css.color = Color.new(0, 255, 0);
is $css.color, '#00FF00', 'color assignment';
is ~$css, 'color:lime;', 'color assigment';

done-testing;
