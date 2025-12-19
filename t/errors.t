use CSS::Properties;
use Test;

plan 6;

my CSS::Properties $css .= new;

$css.width = "2em";
is $css, "width:2em;";
quietly { $css.width = "2furlongs" };
is $css, "";
is $css.width, "auto";
dies-ok { $css.foo = "2em" };

quietly { $css.width = "foo(42)"; }
is $css, "";

$css.width = "calc(42)";
is $css, "";
$css.width = "calc(2em + 3hz)";
$css.width = "calc('foo')";
