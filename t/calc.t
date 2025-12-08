use CSS::Properties;
use CSS::Units :pt, :px;
use Test;

plan 7;

my CSS::Properties $css .= new;
is $css.measure(:font-size), 12;
$css.font-size = 'calc((50% + 70%)/2)';
is $css.Str, 'font-size:calc((50%+70%)/2);';
is $css.measure(:font-size), 7.2;
$css.width = 'calc(em * 2)';
is $css.measure(:width), 14.4;
$css.width = 'calc(2pt + 3px)';
is $css.measure(:width), $css.measure(2pt) + $css.measure(3px);
$css.width = 'calc(1pt + 1pt + (1 + 2)*1px)';
is $css.measure(:width), $css.measure(2pt) + $css.measure(3px);
$css.font-size = Nil;
is $css.Str, 'width:calc(1pt+1pt+(1+2)*1px);';
