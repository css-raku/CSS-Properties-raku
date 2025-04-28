use v6;
use Test;
plan 30;

use CSS::Units :pt, :px, :pc, :in, :vw, :vh, :em, :ex, :percent;
use CSS::Properties;
use CSS::Module;
use CSS::Module::SVG;

my CSS::Properties $css .= new: :viewport-width(200pt), :viewport-height(100pt);
is '%0.2f'.sprintf($css.measure($css.viewport-width)), '200.00', '$css.measure($.viewport-width)';
is '%0.2f'.sprintf($css.measure($css.viewport-height)), '100.00', '$css.measure($.viewport-height)';

is $css.units, 'pt', 'default units';
is $css.measure(10pt), 10, '$css.measure(pt)';

is '%0.2f'.sprintf($css.measure(10px)), '7.50', '$css.measure(px)';
is '%0.2f'.sprintf($css.measure(1pc)), '12.00', '$css.measure(pc)';
is '%0.2f'.sprintf($css.measure(1em)), '12.00', '$css.measure(em)';
is '%0.2f'.sprintf($css.measure(1ex)), '9.00', '$css.measure(ex)';
is '%0.2f'.sprintf($css.measure(.1vw)), '20.00', '$css.measure(vw)';
is '%0.2f'.sprintf($css.measure(.1vh)), '10.00', '$css.measure(vh)';
is '%0.2f'.sprintf($css.measure: 'thin'), '1.00', '$css.measure("thin")';
is '%0.2f'.sprintf($css.measure: 'medium'), '2.00', '$css.measure("medium")';
is '%0.2f'.sprintf($css.measure: :font-size<medium>), '12.00', '$css.measure(:font-size<medium>)';
is '%0.2f'.sprintf($css.measure: :font-size<thick>), '3.00', '$css.measure("thick")';
is '%0.2f'.sprintf($css.measure: :font-size<x-large>), '18.00', '$css.measure("x-large")';
is '%0.2f'.sprintf($css.measure: :font-size<smaller>), '10.00', '$css.measure("smaller")';

$css .= new: :style("border-spacing: 3pt .75em");
is $css.measure(:border-spacing), [3.0, 9.0];

$css .= new: :style("height:5px");
is $css.measure(:height), 15/4;
is $css.measure(:height($css.height)), 15/4;

# change base units
$css .= new: :units<pc>;
is $css.units, 'pc', 'changed units';
is '%0.2f'.sprintf($css.measure(1pc)), '1.00', '$css.measure(in)';
is '%0.2f'.sprintf($css.measure(1in)), '6.00', '$css.measure(in)';
is '%0.2f'.sprintf($css.measure(12pt)), '1.00', '$css.measure(in)';

# SVG specifics
my CSS::Module:D $module = CSS::Module::SVG.module;
$css .= new: :$module, :user-width(1.5), :viewport-width(200pt), :viewport-height(100pt);
is '%0.2f'.sprintf($css.measure: :stroke-width(2pt)), '2.00';
is '%0.2f'.sprintf($css.measure: :stroke-width(10%)), '20.00';
is '%0.2f'.sprintf($css.measure: :stroke-width(10)), '15.00';
is '%0.2f'.sprintf($css.measure: :opacity(.5)), '0.50';
is '%0.2f'.sprintf($css.measure: :opacity(70%)), '0.70';
is '%0.2f'.sprintf($css.measure: :opacity(1.1)), '1.00';
is '%0.2f'.sprintf($css.measure: :opacity(-1.1)), '0.00';

done-testing;
