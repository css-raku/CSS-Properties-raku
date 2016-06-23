use v6;

use CSS::Declarations::Property;
use CSS::Declarations::Box;


class CSS::Declarations {

    my enum Units « :pt(1.0) :pc(12.0) :px(.75) :mm(28.346) :cm(2.8346) »;

    #| contextual variables
    has Numeric $.em;     #| font-size scaling factor, e.g.: 2em
    has Numeric $.ex;     #| font x-height scaling factor, e.g.: ex
    has Units $.length-units;  #| target units
    has Any %!values;  #| property values

    our %properties;   #| property definitions

    BEGIN my $module = CSS::Module::CSS3.module;
    BEGIN my %metadata = $module.property-metadata;

    multi sub make-property( Str $name where { %properties{$name}:exists })  {
        %properties{$name}
    }

    multi sub make-property(Str $name) {
        if $name ~~ /^'@'/ {
            warn "todo: $name";
            return;
        }
        with %metadata{$name} -> %defs {
            with %defs<children> {
                # e.g. margin, comprised of margin-top, margin-right, margin-bottom, margin-left
                for .list -> $side {
                    # these shouldn't nest or cycle
                    make-property($side);
                    %defs{$side} = $_ with %properties{$side};
                }
                if %defs<box> {
                    %properties{$name} = CSS::Declarations::Box.new( :$name, |%defs);
                }
                else {
                    # ignore compound properties, e.g. background, font 
                }
            }
            else {
                %properties{$name} = CSS::Declarations::Property.new( :$name, |%defs );
            }
        }
        else {
            die "unknown property: $name"
        }

    }

    BEGIN {
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
            .value.box ?? 'box' !! 'item';
        }
        for %prop-type<item>.list {
            %!values{.key} = self.from-ast( .value.default-ast );
        }
        for %prop-type<box>.list {
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

    method !box-proxies(Str $prop, List $children) is rw {
	Proxy.new(
	    FETCH => sub ($) { %!values{$prop} },
	    STORE => sub ($,$v) {
		# expand and assign values to child properties
		my @v = $v.isa(List) ?? $v.list !! [$v];
		@v[1] //= @v[0];
		@v[2] //= @v[0];
		@v[3] //= @v[1];
		my $n = 0;
		%!values{$_} = @v[$n++]
		    for $children.list;
	    });
    }

    multi method FALLBACK(Str $prop) is rw {
        with %metadata{$prop} {
            my &meth =
                .<box>
		    ?? method () is rw { self!box-proxies($prop, .<children>) }
		    !! method () is rw { %!values{$prop} };
	
	    self.^add_method($prop,  &meth);
            self."$prop"();
        }
        else {
            nextsame;
        }
    }
}
