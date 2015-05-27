use v6;

use CSS::Module::CSS3;
use CSS::Module::CSS3::MetaData;

class CSS::Node::Property {

    has Str $.name;
    has Bool $.inherit;
    has Str $.synopsis;
    has Str $.default;
    has Bool $.box;

    BEGIN our %property-metadata = $CSS::Module::CSS3::MetaData::property.list;
    BEGIN our $property-grammar = CSS::Module::CSS3;
    BEGIN our $property-actions = CSS::Module::CSS3::Actions.new;
    our %property-expr;

    multi submethod BUILD( Str :$!name!, :$!synopsis!, :$!default, :$!inherit = False, :$!box = False ) {
    }

    multi submethod BUILD(Str :$name!) {
        die "unknown property: $name"
            unless %property-metadata{$name}:exists;

        die "malformed metadata for property $name"
            unless %property-metadata{$name}<synopsis>:exists;

        self.BUILD( :$name, |%( %property-metadata{$name} ) );
    }

    #| 'compiled' default value
    method default-ast {
        if $!default.defined {
            unless %property-expr{$!default}:exists {
                %property-expr{$!default} = do {
                    $property-grammar.parse( $!default, :rule<expr>, :actions($property-actions) )
                        or die "unable to parse default expression for property $!name: $!default"
                };
            }

            %property-expr{$!default}.ast;
        }
    }

}
