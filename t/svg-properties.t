#!/usr/bin/env perl6

use Test;
use JSON::Fast;

use CSS::Module::SVG;
use CSS::Properties;

my CSS::Module $module = CSS::Module::SVG.module;

for 't/svg-properties.json'.IO.lines {

    next if .substr(0,2) eq '//';
    my %test = %( from-json($_) );
    my $prop = %test<prop>.lc;
    my $expr = %test<expr>;

    my $style = sprintf '%s:%s;', $prop, %test<decl>;
    my $out-prop =  %test<out-prop> // $prop;
    my $out-val =  %test<out> // %test<decl>;
    my $expected = $out-val
                    ?? sprintf '%s:%s;', $out-prop, $out-val
                    !! '';

    my CSS::Properties $css .= new: :$module, :$style;
    is $css.Str, $expected, $style;
    with %test<type> {
        isa-ok $css."$prop"(), $_, "$style - type";
    }
}

done-testing;
