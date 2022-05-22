use Test;
plan 4;
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

todo "may fail on older Rakudo versions"
  if $*RAKU.compiler.version < v2022.03;
nok $err, 'no property name errors';


use CSS::Module;
use CSS::Module::CSS1;
use CSS::Module::CSS21;
use CSS::Module::CSS3;
my CSS::Module:D @modules = (CSS::Module::CSS1, CSS::Module::CSS21, CSS::Module::CSS3).map: *.module;
my CSS::Properties:D @css = @modules.map: -> $module {CSS::Properties.new: :$module};
blat 'mixed modules',  {
    for @css -> $css, {
        $css.color = <red green blue>.pick;
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
}

done-testing;
