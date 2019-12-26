use v6;
use Test;
use CSS::Units :cm, :in, :mm, :pt, :px, :pc, :ops, :ms, :hz, :turn;

my $r = 1pt + 2pt;
is $r, '3', 'pt + pt';
is $r.type, 'pt', 'pt + pt';
is $r.gist, '3pt', 'gist';

$r += 3pt;
is $r, '6', 'pt += pt';
is $r.type, 'pt', 'pt += pt';

$r = 1pt + 1.76389mm;
is '%0.2f'.sprintf($r), '6.00', 'pt + mm';
is $r.type, 'pt', 'pt + mm';

$r = 1pt + 1.76389cm;
is '%0.2f'.sprintf($r), '51.00', 'pt + mm';

$r = 12pt - 0.138889in;
is '%0.2f'.sprintf($r), '2.00', 'pt - in';

is '%0.2f'.sprintf(0pt + 1in), '72.00', 'pt + in';
is '%0.2f'.sprintf(0pt +css 1in), '72.00', 'pt +css in';
is '%0.2f'.sprintf(1pt + 10px), '8.50', 'pt + px';
is '%0.2f'.sprintf(2pt + 1pc), '14.00', 'pt + pc';
is '%0.2f'.sprintf(1pc - 2pt), '0.83', 'pt - pc';
is '%0.2f'.sprintf(1pc -css 2pt), '0.83', 'pt -css pc';

is-approx 1500ms.scale("s"), 1.50, 'ms to s';
is-approx 1200hz.scale("khz"), 1.20, 'hz to khz';

is-approx 1turn.scale("deg"), 360, 'turn to deg';
is-approx 1turn.scale("rad"), (2*pi), 'turn to rad';

done-testing;
