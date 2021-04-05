use v6;
use Test;
plan 13;
require CSS::Module::CSS3;
use CSS::Properties;

my %extensions = %(
    '-my-align' => %(
        :synopsis('left | middle | right'),
        :default<middle>,
        :coerce(-> Str() $keyw { :$keyw }),
    ),
    '-my-span' => %(
        :synopsis<integer>,
        :default(1),
        :coerce(-> Int() $num { :$num }),
    ),
);

my $module = CSS::Module::CSS3.module: :%extensions;

my $css = CSS::Properties.new( :$module, );
my $info = $css.info('-my-align');
is $info.name, '-my-align', 'info.name';
is $info.synopsis, 'left | middle | right', 'info.synopsis';
is $info.default, 'middle', 'info.default';
is $info.default-type, 'keyw', 'info.default-type';

$css."-my-span"() = 5;
is $css."-my-span"(), 5;

lives-ok {$css."-my-align"() = 'left'}, 'property set';
is $css."-my-align"(), 'left', 'property get';
is $css.properties.sort.join(','), '-my-align,-my-span', 'properties';
is $css.Str, '-my-align:left; -my-span:5;', 'serialization';

$css."-my-align"() = 'middle';

is $css.Str, '-my-span:5;', 'serialization (default)';

$css .= new: :style($css.Str), :$module;

is $css.Str, '-my-span:5;', 'reserialization';
is $css."-my-span"(), 5;
is $css."-my-align"(), 'middle';

done-testing;
