use v6;

use CSS::Declarations::Property;
use CSS::Declarations::Box;

class CSS::Declarations {

    my enum Units « :pt(1.0) :pc(12.0) :px(.75) :mm(28.346) :cm(2.8346) »;

    #| contextual variables
    has Numeric $.em;     #| font-size scaling factor, e.g.: 2em
    has Numeric $.ex;     #| font x-height scaling factor, e.g.: ex
    has Units $.length-units;  #| target units

    our %properties;   #| property definitions
    has Any %!values;  #| property values

    BEGIN my $module = CSS::Module::CSS3.module;

    multi sub make-property( Str $name where { %properties{$name}:exists })  {
        %properties{$name}
    }

    multi sub make-property(Str $name) {
        my %metadata = $module.property-metadata;
        if $name ~~ /^'@'/ {
            warn "todo: $name";
            return;
        }
        die "unknown property: $name"
            unless %metadata{$name}:exists;
        my %defs = %metadata{$name};
        my $class = CSS::Declarations::Property;
        if %metadata{$name}<children>:exists {
            # e.g. margin, comprised of margin-top, margin-rgit, margin-bottom, margin-left
            $class = CSS::Declarations::Box;
            for %metadata{$name}<children>.list -> $side {
                # these shouldn't nest or cycle
                die "property has unexpected children: $side"
                    if %metadata{$side}<children>:exists
                    || $side eq $name;                         
                %defs{$side} = make-property($side);
            }
        }
        %properties{$name} = $class.new( :$name, |%defs );
    }

    BEGIN {
        my %metadata = $module.property-metadata;
        make-property($_)
            for %metadata.keys.sort;
    }

    multi method from-ast(List $v) {
        $v.elems == 1
            ?? self.from-ast( $v[0] )
            !! [ $v.map: {self.from-ast($_) } ];
    }
    #| { :int(42) } => :int(42)
    multi method from-ast(Hash $v where .keys == 1) {
        self.from-ast($v.values[0]);
    }
    multi method from-ast(Pair $v) {
        given .key {
            when 'pt'|'pc'|'px'|'mm'|'cm' {
                self.length-units * $v.value / Units.enums{$_};
            }
            default {
                warn "ignoring ast tag: $_";
                self.from-ast($v.value);
            }
        }
    }
    multi method from-ast($v) is default {
        $v
    }

    submethod BUILD( :$!em = 16 * px,
                     :$!ex = 12 * px,
                     :$!length-units = px,
                     *@values ) {
        # default any missing CSS values
        my %prop-type = %properties.classify: {
            .value.children ?? 'parent' !! 'item';
        }
        for %prop-type<item>.list {
            %!values{.key} = self.from-ast( .value.default-ast );
        }
        for %prop-type<parent>.list {
            # bind to the child values.
            my @bound;
            my $n;
            for .value.children.list {
                @bound[$n++] := %!values{$_};
            }
            %!values{.key} = @bound;
        }
        # todo apply values
    }

    method FALLBACK(Str $prop) {
        nextsame unless %properties{$prop}:exists;
        self.^add_method($prop,  method () { %!values{$prop} } );
        self."$prop"();
    }
}
