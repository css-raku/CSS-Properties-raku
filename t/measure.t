use v6;
use Test;
plan 17;
use CSS::Units :pt, :px, :pc, :in, :vw, :vh;

sub value($v, $u) { CSS::Units.value($v, $u) }
sub keyw($v) { value($v, 'keyw') }

use CSS::Properties;
my CSS::Properties $css .= new: :viewport-width(200pt), :viewport-height(100pt);
is '%0.2f'.sprintf($css.measure($css.viewport-width)), '200.00', '$css.measure($.viewport-width)';
is '%0.2f'.sprintf($css.measure($css.viewport-height)), '100.00', '$css.measure($.viewport-height)';

is $css.measure(10pt), 10, '$css.measure(pt)';

is '%0.2f'.sprintf($css.measure(10px)), '7.50', '$css.measure(px)';
is '%0.2f'.sprintf($css.measure(1pc)), '12.00', '$css.measure(pc)';
is '%0.2f'.sprintf($css.measure(value(1, "em"))), '12.00', '$css.measure(em)';
is '%0.2f'.sprintf($css.measure(value(1, "ex"))), '9.00', '$css.measure(ex)';
is '%0.2f'.sprintf($css.measure(.1vw)), '20.00', '$css.measure(vw)';
is '%0.2f'.sprintf($css.measure(.1vh)), '10.00', '$css.measure(vh)';
is '%0.2f'.sprintf($css.measure: keyw('thin')), '1.00', '$css.measure("thin")';
is '%0.2f'.sprintf($css.measure: keyw('medium')), '2.00', '$css.measure("medium")';
is '%0.2f'.sprintf($css.measure: :font-size(keyw('medium'))), '12.00', '$css.measure(:font-size<medium>)';
is '%0.2f'.sprintf($css.measure: :font-size(keyw('thick'))), '3.00', '$css.measure("thick")';
is '%0.2f'.sprintf($css.measure: :font-size(keyw('x-large'))), '18.00', '$css.measure("x-large")';

# change base units
$css .= new: :units<pc>;
is '%0.2f'.sprintf($css.measure(1pc)), '1.00', '$css.measure(in)';
is '%0.2f'.sprintf($css.measure(1in)), '6.00', '$css.measure(in)';
is '%0.2f'.sprintf($css.measure(12pt)), '1.00', '$css.measure(in)';

done-testing;
