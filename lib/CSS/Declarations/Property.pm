use v6;

use CSS::Module::CSS3;
use CSS::Module::CSS3::Metadata;

class CSS::Declarations::Property {

    has Str $.name;
    has Bool $.inherit;
    has Str $.synopsis;
    has Str $.default;
    has $.default-ast;

    method box { False }

    our  %Metadata;
    BEGIN {
        %Metadata = %$CSS::Module::CSS3::Metadata::property;
    }

    multi method build( Str :$!name!, :$!synopsis!, Array :$default, :$!inherit = False, Bool :$box = False ) {
        die "$!name css property should be composed via CSS::Declarations::Box"
            if $box && !self.box;
        # second entry is the compiled default value
         with $default {
             $!default = .[0];
             $!default-ast = .[1];
         }
    }

    multi method build(Str :$name!) is default {
        die "unknown property: $name"
            unless %Metadata{$name}:exists;

        die "malformed metadata for property $name"
            unless %Metadata{$name}<synopsis>:exists;

        self.build( :$name, |%Metadata{$name} );
    }

    submethod BUILD(|c) {
        self.build(|c)
    }

}
