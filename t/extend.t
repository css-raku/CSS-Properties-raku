use v6;
use Test;
plan 18;
require CSS::Module::CSS3;
use CSS::Properties;

my $my-align-calls;
my $my-span-calls;

subset Synopsis of Str where 'left'|'middle'|'right';

my %extensions = %(
    '-my-align' => %(
        :synopsis('left | middle | right'),
        :default<middle>,
        :coerce(-> Synopsis() $keyw {$my-align-calls++; :$keyw }),
    ),
    '-my-span' => %(
        :synopsis<integer>,
        :default(42),
        :coerce(-> Int() $num {$my-span-calls++; :$num }),
    ),
);

my $module = CSS::Module::CSS3.module: :%extensions;

my CSS::Properties $css .= new( :$module, );
my $info = $css.info('-my-align');
is $info.name, '-my-align', 'info.name';
is $info.synopsis, 'left | middle | right', 'info.synopsis';
is $info.default, 'middle', 'info.default';
is $info.default-type, 'keyw', 'info.default-type';

$css."-my-span"() = 5;
ok $my-span-calls, 'coercer called';
is $css."-my-span"(), 5;
isa-ok $css."-my-span"(), Int;

lives-ok {$css."-my-align"() = 'left'}, 'property set';
ok $my-align-calls, 'coercer called';
is $css."-my-align"(), 'left', 'property get';
is $css.properties.sort.join(','), '-my-align,-my-span', 'properties';
is $css.Str, '-my-align:left; -my-span:5;', 'serialization';

$css."-my-align"() = 'middle';

is $css.Str, '-my-span:5;', 'serialization (default)';

$css .= new: :style($css.Str), :$module;

is $css.Str, '-my-span:5;', 'reserialization';
is $css."-my-span"(), 5;
is $css."-my-align"(), 'middle';

subtest 'parse' => {
    $my-span-calls = 0;
    $my-align-calls = 0;
    my $style = "-my-align:left; -my-span:3; color:red;";
    $css .= new: :$module, :$style;
    ok $my-span-calls, 'coercer called';
    ok $my-align-calls, 'coercer called';
    is $css.Str, $style, 'serialization';
    is $css."-my-span"(), 3;
    isa-ok $css."-my-span"(), Int;
    is $css."-my-align"(), 'left';
}

subtest 'invalid' => {
    my $style = "-my-align:42; -my-span:xxx; color:red;";
    $css .= new: :$module, :$style, :!warn;
    is $css.Str, 'color:red;', 'serialization';
    is $css."-my-span"(), 42;
    isa-ok $css."-my-span"(), Int;
    is $css."-my-align"(), 'middle';
}

done-testing;
