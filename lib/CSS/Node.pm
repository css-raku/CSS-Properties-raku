use v6;

use CSS::Node::Property;
use CSS::Node::Box;

class CSS::Node {

    has CSS::Node::Property $.property handles <inherit synopsis box name default default-expr>;

    #| contextual variables
    has Numeric:U $.em;
    has Numeric:U $.ex;

    #| these implement the CSS Box Model
    has CSS::Node::Box $.margin;
    has CSS::Node::Box $.border;
    has CSS::Node::Box $.padding;

    submethod BUILD( :$name!, :$!em, :$!ex, :$!margin, :$!border, :$!padding ) {
        $!property = CSS::Node::Property.new( :$name );
    }
}
