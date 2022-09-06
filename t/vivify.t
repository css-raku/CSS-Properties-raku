use v6;
use Test;
plan 6;
require CSS::Module::CSS3;
use CSS::Properties;
use CSS::Units :em;

my $module = CSS::Module::CSS3.module: :vivify;

my $style = "bar:yup; color:red; foo:42;";
my CSS::Properties $css .= new: :$module, :$style;
my $info = $css.info('foo');
is $info.name, 'foo', 'vivifed-name';

is $css.Str, $style;

is $css.foo, 42;
$css.foo = Nil;
$css.bar = 42;

is $css.Str, "bar:42; color:red;";

$css.baz = 99em
;
is-deeply $css.blah, Any;

is $css.Str, "bar:42; baz:99em; color:red;";

done-testing;
