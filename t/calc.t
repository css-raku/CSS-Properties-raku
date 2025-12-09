use CSS::Properties;
use CSS::Units :pt, :px;
use Test;

plan 4;

my CSS::Properties $css .= new;
subtest 'font-size', {
    is $css.measure(:font-size), 12;
    $css.font-size = 'calc((50% + 70%)/2)';
    is $css.Str, 'font-size:calc((50%+70%)/2);';
    is $css.measure(:font-size), 7.2;
    $css.font-size = Nil;
}
subtest 'basic arithmetic', {
    $css.width = 'calc(em * 2)';
    is $css.measure(:width), 14.4;
    $css.width = 'calc(2pt + 3px)';
    is $css.measure(:width), $css.measure(2pt) + $css.measure(3px);
    $css.width = 'calc(1pt + 1pt + (1 + 2)*1px)';
    is $css.measure(:width), $css.measure(2pt) + $css.measure(3px);
    is $css.Str, 'width:calc(1pt+1pt+(1+2)*1px);';
}
subtest 'associativety/precedence', {
    $css.width = 'calc(1pt + 2pt * 2 + 1pt)';
    is $css.measure(:width), 6;
    is $css.Str, 'width:calc(1pt+2pt*2+1pt);';
    $css.width = 'calc((1pt + 2pt) * 2 + 1pt)';
    is $css.measure(:width), 7;
    is $css.Str, 'width:calc((1pt+2pt)*2+1pt);';
}
subtest 'div/minus', {
    $css.width = 'calc(6pt / (2))';
    is $css.measure(:width), 3;
    is $css.Str, 'width:calc(6pt/(2));';
    $css.width = 'calc(6pt - 2px)';
    is $css.measure(:width), 4.5;
    is $css.Str, 'width:calc(6pt-2px);';
}
