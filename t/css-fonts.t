use v6;
use Test;
plan 3;
use CSS::Properties;

my $style = 'font:italic bold 10pt/12pt times-roman;';
my CSS::Properties $css .= new: :$style;

subtest 'props' => {
    is $css.font-style, 'italic', 'font-style';
    is $css.font-weight, 'bold', 'font-weight';
    is $css.font-family, 'times-roman', 'font-family';
    is $css.font-size, 10, 'font-size';
    is $css.line-height, 12, 'line-height';
}

# check round-trip of font properties samples

subtest 'serialization' => {
    plan 33;
    is ~$css, $style, 'serialization';
    my @props = (:font-style<italic>, :font-weight<bold>,
                 :font-size<10pt>, :line-height<12pt>,
                 :font-family<times-roman>
                );

    # basic check that every combination of font properties can be serialised and round-tripped
    for 0 ..^ 2**5 -> $mask {
        my @pick = $mask.fmt('%05b').comb>>.Int;
        my %props = @props.keys.grep({@pick[$_]}).map({@props[$_]});
        my CSS::Properties $css .= new: |%props;
        my $style = ~$css;
        $css .= new: :$style;
        my @prop-names = %props.keys.sort;
        is-deeply $css.keys.sort.Array, @prop-names, (@prop-names||'(empty)').join(' ');
    }
}

subtest 'issue#23', {
    my CSS::Properties $css .= new: :style("font-size:.85em");
    is $css.clone.measure(:font-size), $css.measure(:font-size);
}

done-testing;
