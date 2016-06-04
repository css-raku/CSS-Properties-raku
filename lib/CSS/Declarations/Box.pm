use v6;

use CSS::Declarations::Property;

class CSS::Declarations::Box
    is CSS::Declarations::Property {
    method box { True }

    has CSS::Declarations::Property $.top;
    has CSS::Declarations::Property $.left;
    has CSS::Declarations::Property $.bottom;
    has CSS::Declarations::Property $.right;
}
