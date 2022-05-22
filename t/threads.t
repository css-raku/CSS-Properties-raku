use Test;
plan 3;
use CSS::Properties;
use CSS::Units :pt;

constant MAX_THREADS=10;
constant MAX_LOOP=24;

sub blat($test, &r, :$n = MAX_THREADS) {
    my @res;
    lives-ok {
        for 1..MAX_LOOP {
            @res = (^$n).race(:batch(1)).map(&r)}
    }, $test;

    @res;
}

blat 'basic', {
    my CSS::Properties() $css = "color:red !important; padding: 1pt";
    $css.border-color = 'red';

    $css.margin = [5pt, 2pt, 5pt, 2pt];
    $css.margin = 5pt;  # set margin on all 4 sides

    # set text alignment
    $css.text-align = 'right';

}

my atomicint $err = 0;
my CSS::Properties() $css = "color:red !important; padding: 1pt";
blat 'info', {
    for $css.module.prop-names.values.pick(5) {
        my $info = $css.info($_);
        my $num = $info.prop-num;
        unless $num == $_ {
            unless $err⚛++ > 5  {
                diag "property number mismatch: $num <-> $_";
            }
        }
    }
}

nok $err, 'no property name errors';
