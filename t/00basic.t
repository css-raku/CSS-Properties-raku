use v6;
use Test;
use CSS::Declarations::Property;
use CSS::Declarations::Box;

pass('compiles');

my $sample-prop = CSS::Declarations::Property.new( :name<background-image> );

is-deeply $sample-prop.name, 'background-image', '$prop.name';
is-deeply $sample-prop.box, False, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<uri> | none', '$prop.synopsis';
is-deeply $sample-prop.default, "none", '$prop.default';
is-deeply $sample-prop.default-ast, [{:keyw<none>},], '$prop.default-ast';

$sample-prop = CSS::Declarations::Box.new( :name<margin> );

is-deeply $sample-prop.name, 'margin', '$prop.name';
is-deeply $sample-prop.box, True, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '[<length> | <percentage> | auto ]{1,4}', '$prop.synopsis';

done-testing;
