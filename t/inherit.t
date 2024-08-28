use v6;
use Test;
plan 21;
use CSS::Properties;

my $inherit = CSS::Properties.new: :style("margin-top:5pt; margin-right: 10pt; margin-left: 15pt; margin-bottom: 20pt; color:rgb(0,0,255)!important");

is-deeply ($inherit.inherited), ('color',); 

my $css = CSS::Properties.new( :style("margin-top:25pt; margin-right: initial; margin-left: inherit"), :$inherit );

nok $css.handling("margin-top"), 'overridden value';
is $css.margin-top, 25, "overridden value";

is $css.handling("margin-right"), "initial", "'initial'";
is $css.margin-right, 0, "'initial'";

is $css.handling("margin-left"), "inherit", "'inherit'";
is $css.margin-left, 15, "'inherit'";

is $css.info("color").inherit, True, 'color inherit metadata';
is $css.color, '#0000FF', "inherited property";

is $css.info("margin-bottom").inherit, False, 'margin-bottom inherit metadata';
is $css.margin-bottom, 0, "non-inhertiable property";

$css = CSS::Properties.new( :style("margin: inherit"), :$inherit);
is $css.margin-top, 5, "inherited box value";
is $css.margin-right, 10, "inherited value";

$css = CSS::Properties.new( :style("margin: initial; color:purple"), :$inherit);
is $css.margin-top, 0, "initial box value";
is $css.color, '#7F007F', "inherited !important property";
nok $css.important("color"), '!important is not inherited';

# inherit from css object
is ~$css, 'color:purple; margin:initial;', 'inherit from object';

# inherit from style string
$css = CSS::Properties.new( :inherit(~$inherit));
is ~$css, 'color:blue;', 'inherit from string';

subtest 'font-size inheritance', {
    $inherit = CSS::Properties.new: :style("font-size: 15pt;");
    $css = CSS::Properties.new: :style("color:red");
    $css.inherit: $inherit;
    is ~$css, 'color:red; font-size:15pt;', 'inherit absolute font-size';
    is $css.measure(:font-size), 15;

    $inherit = CSS::Properties.new: :style("font-size: larger;");
    $css = CSS::Properties.new: :style("color:red; font-size:inherit;"), :$inherit;
    is ~$css, 'color:red; font-size:14.4pt;', 'inheritance of relative font-size';

    $inherit = CSS::Properties.new: :style("font-size: 40pt;");
    $css = CSS::Properties.new: :style("font-size:75%;"), :$inherit;
    is ~$css, 'font-size:75%;', 'relative font-size inheritance';
    is $inherit.measure(:font-size), 40, 'inherited font size measurement';
    is $inherit.computed('font-size'), 40, 'computed font size measurement';
    is $css.measure(:font-size), 30, 'relative font size measurement';
    is $css.computed('font-size'), 30, 'relative font size measurement';
}

subtest 'inherit+clone', {
    my CSS::Properties $valign-middle .= new(:vertical-align<middle>);
    $css .= new: :style("border-top-color:red; vertical-align:inherit;");
    my $original-css = $css;
    $css .= clone;
    is ~$css, "border-top:red; vertical-align:inherit;", 'cloned css';
    $css.border-color = 'blue';
    is ~$css, "border:blue; vertical-align:inherit;", 'cloned css';
    $css.inherit: $valign-middle;
    is ~$css, "border:blue; vertical-align:middle;", 'cloned+inherited css';

    $css = $original-css.clone;
    $css.inherit: $valign-middle;
    $css .= clone;
    is ~$css, "border-top:red; vertical-align:middle;", 'inherited+cloned css';

    $css = $original-css.clone;
    $css.vertical-align = 'bottom';
    $css.vertical-align = Nil;
    is ~$css, "border-top:red; vertical-align:inherit;";
    $css.inherit: $valign-middle;
    is ~$css, "border-top:red; vertical-align:middle;";

    $css = $original-css.clone;
    $css.vertical-align = 'bottom';
    $css.inherit: $valign-middle;
    is ~$css, "border-top:red; vertical-align:bottom;";

    is ~$original-css, "border-top:red; vertical-align:inherit;", 'original css';
}

subtest 'issue#11 inheritence', {
    plan 2;
    my $style = "color:purple; font-style:italic;";
    my CSS::Properties $parent .= new: :$style;
    my CSS::Properties $child .= new;

    $child.inherit($parent);

    is $parent, $style;
    is $child, $style;
}

done-testing;
