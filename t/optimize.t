use v6;
use Test;
plan 16;

use CSS::Properties;
use CSS::Module::CSS3;
use CSS::Writer;

my $css = CSS::Properties.new;
my $module = CSS::Module::CSS3.module;
my $writer = CSS::Writer.new: :color-names, :!pretty;
constant Unchanged = Any;

for (
    "border-bottom-color:red; border-bottom-style:solid; border-bottom-width:1px; border-left-color:red; border-left-style:solid; border-left-width:1px; border-right-color:red; border-right-style:solid; border-right-width:1px; border-top-color:red; border-top-style:solid; border-top-width:1px;" => "border:1px solid red;",
    "border-width:5pt 5px 5in 5mm;" => Unchanged,
    "border-top-width:5px!important;" => 'border-top:5px!important;',
    "border:5pt solid; border-color:red green blue yellow;" => Unchanged,
    "font-family:times; font-size:inherit; font-weight:inherit;" => Unchanged,
    "background:no-repeat 50% 75%;" => Unchanged,
    "font:1.1em/1.3 Verdana, Arial, sans-serif;" => Unchanged,
    "list-style-type:circle;" => "list-style:circle;",
    ) -> \t {
    my $actions = $module.actions.new;
    my $p = $module.grammar.parse(t.key, :rule<declaration-list>, :$actions)
        // die "unable to parse declarations: {t.key}";

    my $ast = $css.optimize($p.ast);
    is $writer.write(|$ast), (t.value//t.key), "optimised ast {t.value//t.key}";
    warn $_
        for $actions.warnings;
    is CSS::Properties.new( :style(t.key) ).Str, (t.value//t.key), "optimised css {t.value//t.key}";
}

done-testing;
