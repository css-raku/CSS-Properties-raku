use v6;

use CSS::Module::CSS3;
use CSS::Module::CSS3::Metadata;

class CSS::Declarations::Property {

    has Str $.name;
    has Bool $.inherit;
    has Str $.synopsis;
    has Str $.default;
    has $.default-ast;
    has Bool $.box;

    our  %PropertyMetadata;
    BEGIN {
        %PropertyMetadata = %$CSS::Module::CSS3::Metadata::property;
    }

    multi submethod BUILD( Str :$!name!, :$!synopsis!, Array :$default, :$!inherit = False, :$!box = False ) {
        # second entry is the compiled default value
         with $default {
             $!default = .[0];
             $!default-ast = .[1];
         }
    }

    multi submethod BUILD(Str :$name!) {
        die "unknown property: $name"
            unless %PropertyMetadata{$name}:exists;

        die "malformed metadata for property $name"
            unless %PropertyMetadata{$name}<synopsis>:exists;

        self.BUILD( :$name, |%PropertyMetadata{$name} );
    }

}
