use v6;

use CSS::Module::CSS3;
use CSS::Module::CSS3::Metadata;

class CSS::Node::Property {

    has Str $.name;
    has Bool $.inherit;
    has Str $.synopsis;
    has Str $.default;
    has $.default-ast;
    has Bool $.box;

    BEGIN our %property-metadata = $CSS::Module::CSS3::Metadata::property.list;
    our %property-expr;

    multi submethod BUILD( Str :$!name!, :$!synopsis!, Array :$default, :$!inherit = False, :$!box = False ) {
        # second entry is the compiled default value
         with $default {
             $!default = $default[0];
             $!default-ast = $default[1];
         }
    }

    multi submethod BUILD(Str :$name!) {
        die "unknown property: $name"
            unless %property-metadata{$name}:exists;

        die "malformed metadata for property $name"
            unless %property-metadata{$name}<synopsis>:exists;

        self.BUILD( :$name, |%( %property-metadata{$name} ) );
    }

}
