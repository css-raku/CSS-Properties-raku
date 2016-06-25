use v6;
use CSS::Declarations;
use Test;

my $css = CSS::Declarations.new;

nok $css.important('background-image');
$css.important('background-image') = True;
ok $css.important('background-image');
$css.important('background-image') = False;
nok $css.important('background-image');

nok $css.important('margin-top');
nok $css.important('margin');

$css.important('margin-top') = True;
ok $css.important('margin-top'), 'importance setter';

$css.important('margin') = True;
ok $css.important('margin'), 'importance setter - box';
ok $css.important('margin-bottom'), 'importance setter - box';

$css.important('margin-bottom') = False;
nok $css.important('margin-bottom');
nok $css.important('margin');
ok $css.important('margin-top');

done-testing;