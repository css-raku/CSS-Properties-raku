use v6;

use CSS::Declarations::Property;
use CSS::Declarations::Box;

class CSS::Declarations {

    has CSS::Declarations::Property $.property handles <inherit synopsis box name default default-expr>;

    #| contextual variables
    has Numeric:U $.em;
    has Numeric:U $.ex;

    #| these implement the CSS Box Model
    has CSS::Declarations::Box $.margin;
    has CSS::Declarations::Box $.border;
    has CSS::Declarations::Box $.padding;

    submethod BUILD( :$name!, :$!em, :$!ex, :$!margin, :$!border, :$!padding ) {
        $!property = CSS::Declarations::Property.new( :$name );
    }
}
