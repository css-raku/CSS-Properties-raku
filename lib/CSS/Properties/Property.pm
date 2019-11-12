use v6;

use CSS::Module;
use CSS::Module::Property;

class CSS::Properties::Property {

    has CSS::Module::Property $.meta handles<inherit synopsis default edge edges children>;
    has Str $.name;
    method box { False }

    multi method build( Str :$!name!, :$!meta! ) {
        die "$!name css property should be composed via CSS::Properties::Edges"
            if $!meta.box && !self.box;
    }

    multi method build(Str :$name!, CSS::Module :$module = (require CSS::Module::CSS3).module) is default {
        my $prop-num = $module.property-number($name)
            // die "property does not exist: $name";
        my $meta = $module.index[ $prop-num ];

        self.build( :$name, :$meta );
    }

    submethod BUILD(|c) {
        self.build(|c)
    }

}
