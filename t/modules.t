use v6;
use Test;
use CSS::Declarations;
use CSS::Module::CSS1;
use CSS::Module::CSS21;

my $style = 'color: red; azimuth: left';
my $module = CSS::Module::CSS1.module;
my $css1 = CSS::Declarations.new( :$style, :$module);
dies-ok { $css1.property("azimuth") }, "azimuth is unknown in CSS1";
is $css1.warnings, "dropping unknown property: azimuth", 'CSS1 warnings';

$module = CSS::Module::CSS21.module;
my $css21 = CSS::Declarations.new( :$style, :$module);
lives-ok { $css21.property("azimuth") }, "azimuth is known in CSS21";
is $css21.warnings, "", 'Css21 warnings';

done-testing;