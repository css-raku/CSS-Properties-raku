use v6;
use Test;
plan 4;

use CSS::Properties;
use JSON::Fast;
use CSS::Font;
use CSS::Units :px, :percent;
sub keyw($v) { CSS::Units.value($v, 'keyw') }
my $font-props = 'italic bold 10pt/12pt times-roman';
my CSS::Font $font .= new: :$font-props;

subtest 'basic' => {
    plan 8;
    is $font.em, 10, 'em';
    is $font.ex, 7.5, 'ex';
    is $font.style, 'italic', 'font-style';
    is $font.weight, '700', 'font-weight';
    is $font.family, 'times-roman', 'font-family';
    is $font.line-height, 12, 'line-height';
    is $font.units, 'pt', 'measuring unit';
    is $font.Str, "font:{$font-props};", '$font.Str';
}
subtest 'measure' => {
    plan 9;
    is $font.measure(:font-size), 10;
    is $font.measure(:line-height), 12;
    is $font.measure(:font-weight), 700;
    is $font.measure(15px), 11.25, 'measure numeric';
    is $font.measure(:font-size(120%)), 12, 'measure percentage font-size';
    is $font.measure(:font-size(80%)), 8, 'measure percentage font-size';
    is $font.measure(:font-size(0%)), 0, 'measure percentage font-size';
    is $font.measure(:font-size(keyw('medium'))), 12, 'measure named font-size';
    is $font.measure(:font-size(keyw('smaller'))), 10/1.2, 'measure named font-size';
}

subtest 'patterns' => {
    plan 3;
    is $font.fontconfig-pattern, 'times-roman:slant=italic:weight=bold', 'fontconfig-pattern';
    is to-json($font.pattern, :!pretty, :sorted-keys), '{"family":["times-roman"],"stretch":"normal","style":"italic","weight":700}';
    $font .= new: :font-props("500 condensed 12px/30px Georgia, serif, Times");
    is $font.fontconfig-pattern, 'Georgia,serif,Times:weight=medium:width=condensed', 'fontconfig-pattern';
}

subtest 'select' => {
    plan 2;
    # Simulate @font-face selection
    use CSS::Module;
    use CSS::Module::CSS3;
    my CSS::Module:D $module = CSS::Module::CSS3.module.sub-module<@font-face>;
    my CSS::Properties @font-face = (
        "font-family:'Sans-serif'; src:url('/myfonts/serif.otf');",
        "font-family:'Serif'; src:url('/myfonts/serif.otf');",
    ).map: -> $style {CSS::Properties.new: :$style, :$module};
    my $selection = $font.select(@font-face);
    ok defined $selection;
    is $selection.Str, @font-face[1].Str;
}
done-testing;
