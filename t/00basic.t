use Test;
use CSS::Node;
use CSS::Node::Property;
use CSS::Node::Box;

pass('compiles');

my $sample-prop = CSS::Node::Property.new( :name<background-image> );

is-deeply $sample-prop.name, 'background-image', '$prop.name';
is-deeply $sample-prop.inherit, False, '$prop.inherit';
is-deeply $sample-prop.synopsis, '<uri> | none', '$prop.synopsis';
is-deeply $sample-prop.default, 'none', '$prop.default';
is-deeply $sample-prop.default-ast, (:expr([{:ident("none")}])), '$prop.default-ast';

done;
