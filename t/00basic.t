use Test;
use CSS::Node;
use CSS::Node::Property;
use CSS::Node::Box;

pass('compiles');

my $sample-prop = CSS::Node::Property.new( :name<background-image> );

is-deeply $sample-prop.name, 'background-image', '$prop.name';
is-deeply $sample-prop.box, False, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<uri> | none', '$prop.synopsis';
is-deeply $sample-prop.default, "none", '$prop.default';
is-deeply $sample-prop.default-ast, [{:keyw<none>},], '$prop.default-ast';

$sample-prop = CSS::Node::Property.new( :name<margin> );

is-deeply $sample-prop.name, 'margin', '$prop.name';
is-deeply $sample-prop.box, True, '$prop.box';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '[<length> | <percentage> | auto ]{1,4}', '$prop.synopsis';
is-deeply $sample-prop.default, "0 0 0 0", '$prop.default';
is-deeply $sample-prop.default-ast, [{:length(0)}, {:length(0)}, {:length(0)}, {:length(0)}], '$prop.default-ast';

done-testing;
