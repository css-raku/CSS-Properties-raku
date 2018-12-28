use v6;
use Test;
plan 9;

use CSS::Properties::Units :pt, :px, :pc, :in;
use CSS::Properties;
my CSS::Properties $css .= new;

is $css.measure(10pt), 10;

is '%0.2f'.sprintf($css.measure(10px)), '7.50', '$css.measure(px)';
is '%0.2f'.sprintf($css.measure(1pc)), '12.00', '$css.measure(pc)';
is '%0.2f'.sprintf($css.measure(1 does CSS::Properties::Units::Type["em"])), '12.00', '$css.measure(em)';
is '%0.2f'.sprintf($css.measure(1 does CSS::Properties::Units::Type["em"], :em(15))), '15.00', '$css.measure(em)';
is '%0.2f'.sprintf($css.measure(1 does CSS::Properties::Units::Type["ex"])), '9.00', '$css.measure(ex)';

# change base units
$css .= new: :units<pc>;
is '%0.2f'.sprintf($css.measure(1pc)), '1.00', '$css.measure(in)';
is '%0.2f'.sprintf($css.measure(1in)), '6.00', '$css.measure(in)';
is '%0.2f'.sprintf($css.measure(12pt)), '1.00', '$css.measure(in)';

done-testing;
