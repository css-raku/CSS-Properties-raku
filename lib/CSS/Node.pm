use v6;

use CSS::Node::Box;
use CSS::Node::Style;

class CSS::Node {
    has $.object;

    has CSS::Node::Style $.style;
    has CSS::Node:U $.inherits;

    #| contextual variables
    has Numeric:U $.em;
    has Numeric:U $.ex;

    #| these implement the CSS Box Model
    has CSS::Node::Box $.margin;
    has CSS::Node::Box $.border;
    has CSS::Node::Box $.padding;
}
