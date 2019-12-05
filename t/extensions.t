use v6;
use Test;
plan 8;
do {
    try require CSS::Module:ver(v0.5.1+);
    if $! {
        skip-rest("CSS::Module v0.5.1+ needed for extension tests");
        exit 0;
    }
}

require CSS::Module::CSS3;
use CSS::Properties;

my $module = CSS::Module::CSS3.module: :alias{'-xhtml-align' => :like<text-align>};
is $module.index.tail.name, '-xhtml-align';
ok $module.property-number('-xhtml-align');

my $css = CSS::Properties.new( :$module, );
ok $css.property-number('-xhtml-align');
is $css.module.index.tail.name, '-xhtml-align';
is $css.info('-xhtml-align').synopsis, '<align> | justify';
lives-ok { $css.'-xhtml-align'() = 'center'; }

$css.text-align = 'left';

is $css.properties.sort.join(','), '-xhtml-align,text-align';
is $css.Str, '-xhtml-align:center; text-align:left;';

done-testing;
