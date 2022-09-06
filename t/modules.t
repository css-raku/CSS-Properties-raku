use v6;
use Test;
plan 5;

use CSS::Properties;
use CSS::Module;
use CSS::Module::CSS1;
use CSS::Module::CSS21;
use CSS::Module::CSS3;

my $style = 'color: red;';
my CSS::Module $module = CSS::Module::CSS1.module;
my $css1 = quietly { CSS::Properties.new( :$style, :$module) };
dies-ok { $css1.info("azimuth") }, "azimuth is unknown in CSS1";

$style ~= ' azimuth: left';
$module = CSS::Module::CSS21.module;
my $css21 = CSS::Properties.new( :$style, :$module);
lives-ok { $css21.info("azimuth") }, "azimuth is known in CSS21";

$module = CSS::Module::CSS3.module;
my $css3 = CSS::Properties.new( :$style, :$module);
lives-ok { $css3.info("azimuth") }, "azimuth is known in CSS3";

$style = 'src: url(gentium.ttf); azimuth: left';
$module = CSS::Module::CSS3.module.sub-module<@font-face>;
my $css-fontface = quietly { CSS::Properties.new( :$style, :$module, :!warn); }
lives-ok { $css-fontface.info("src") }, 'src is known in @font-face';
dies-ok { $css-fontface.info("azimuth") }, 'azimuth is unknown in @font-face';

done-testing;
