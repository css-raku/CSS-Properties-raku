use v6;
use Test;
plan 5;

use CSS::Properties;
use JSON::Fast;
use CSS::Font;
use CSS::Units :px, :percent;
sub keyw($v) { CSS::Units.value($v, 'keyw') }
my $font-props = 'italic bold condensed 10pt/12pt times-roman';
my CSS::Font $font .= new: :$font-props;

subtest 'basic' => {
    plan 9;
    is $font.em, 10, 'em';
    is $font.ex, 7.5, 'ex';
    is $font.style, 'italic', 'font-style';
    is $font.weight, '700', 'font-weight';
    is $font.family, 'times-roman', 'font-family';
    is $font.line-height, 12, 'line-height';
    is $font.stretch, 'condensed', 'font-stretch';
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
    is $font.fontconfig-pattern, 'times-roman:slant=italic:weight=bold:width=75', 'fontconfig-pattern';
    is to-json($font.pattern, :!pretty, :sorted-keys), '{"family":["times-roman"],"stretch":75,"style":"italic","weight":700}';
    $font .= new: :font-props("500 condensed 12px/30px Georgia, serif, Times");
    is $font.fontconfig-pattern, 'Georgia,serif,Times:weight=medium:width=75', 'fontconfig-pattern';
}

subtest 'match basic' => {
    plan 2;
    # Simulate @font-face selection
    use CSS::Module;
    use CSS::Module::CSS3;
    my CSS::Module:D $module = CSS::Module::CSS3.module.sub-module<@font-face>;
    my CSS::Properties @font-face = (
        "font-family:'Sans-serif'; src:url('/myfonts/serif.otf'); font-stretch:condensed",
        "font-family:'Serif'; src:url('/myfonts/serif.otf');",
        "font-family:'Serif'; src:url('/myfonts/serif-narrow.otf'); font-stretch:semi-condensed;",
        "font-family:'Serif'; src:url('/myfonts/serif-narrow-bold.otf'); font-stretch:semi-condensed; font-weight:500",
    ).map: -> $style {CSS::Properties.new: :$style, :$module};
    my $selection = $font.match(@font-face).first;
    ok defined $selection;
    is $selection.Str, @font-face[3].Str;

}

subtest 'match styles' => {
    plan 6;
    use CSS::Module;
    use CSS::Module::CSS3;
    my CSS::Module:D $module = CSS::Module::CSS3.module.sub-module<@font-face>;
    my @decls = q:to<END>.split(/^^'---'$$/);
        font-family: "DejaVu Sans";
        src: url("fonts/DejaVuSans.ttf");
        ---
        font-family: "DejaVu Sans";
        src: url("fonts/DejaVuSans-Bold.ttf");
        font-weight: bold;
        ---
        font-family: "DejaVu Sans";
        src: url("fonts/DejaVuSans-Oblique.ttf");
        font-style: oblique;
        ---
        font-family: "DejaVu Sans";
        src: url("fonts/DejaVuSans-BoldOblique.ttf");
        font-weight: bold;
        font-style: oblique;
        END

        my CSS::Properties @font-face = @decls.map: -> $style {CSS::Properties.new: :$style, :$module};

        for (
            "" => "Sans.ttf",
            "bold" => "-Bold.ttf",
            "italic" => "-Oblique.ttf",
            "oblique" => "-Oblique.ttf",
            "bold oblique" => "-BoldOblique.ttf",
            "bold italic" => "-BoldOblique.ttf",
        ) {
            my $font-props = "{.key} 12pt DejaVu Sans";
            my CSS::Font $font .= new: :$font-props;
            my CSS::Properties $match = $font.match(@font-face).first;
            ok $match.src.ends-with(.value);
        }
}

done-testing;
