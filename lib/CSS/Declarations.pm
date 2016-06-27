use v6;

use CSS::Declarations::Property;
use CSS::Declarations::Box;

class CSS::Declarations {

    my enum Units is export(:Units) « :pt(1.0) :pc(12.0) :px(.75) :mm(28.346) :cm(2.8346) »;
    use CSS::Module;
    use CSS::Module::CSS3;
    my %module-metadata{CSS::Module};     #| per-module metadata
    my %module-properties{CSS::Module};   #| per-module property definitions

    #| contextual variables
    has Numeric $.em;         #| font-size scaling factor, e.g.: 2em
    has Numeric $.ex;         #| font x-height scaling factor, e.g.: ex
    has Any %!values;         #| property values
    has Bool %!important;
    has %!default;
    has CSS::Module $!module; #| associated module
    has $!delegator handles <coerce>;

    multi sub make-property(CSS::Module $m, Str $name where { %module-properties{$m}{$name}:exists })  {
        %module-properties{$m}{$name}
    }

    multi sub make-property(CSS::Module $m, Str $name) is default {
        if $name ~~ /^'@'/ {
            warn "todo: $name";
            return;
        }
        with %module-metadata{$m}{$name} -> %defs {
            with %defs<children> {
                # e.g. margin, comprised of margin-top, margin-right, margin-bottom, margin-left
                for .list -> $side {
                    # these shouldn't nest or cycle
                    make-property($m, $side);
                    %defs{$side} = $_ with %module-properties{$m}{$side};
                }
                if %defs<box> {
                    %module-properties{$m}{$name} = CSS::Declarations::Box.new( :$name, |%defs);
                }
                else {
                    # ignore compound properties, e.g. background, font 
                }
            }
            else {
                %module-properties{$m}{$name} = CSS::Declarations::Property.new( :$name, |%defs );
            }
        }
        else {
            die "unknown property: $name"
        }
    }

    method !build-style(Str $style) {
        my $rule = "declaration-list";
        my $actions = $!module.actions.new;
        $!module.grammar.parse($style, :$rule, :$actions)
            or die "unable to parse CSS style declarations: $style";
        my @declarations = $/.ast.list;

        for @declarations {
            my $decl = .value;
            given .key {
                when 'property' {
                    my $prop = $decl<ident>;
                    my $expr = self.coerce: $decl<expr>;
                    self."$prop"() = $expr;
                    %!important{$prop} = True if $decl<prio>;
                }
                default {
                    warn "ignoring: $_ declaration";
                }
            }
        }
    }

    sub default-delegator() {
        with 'CSS::Declarations::Delegator' {
            require ::($_);
            ::($_);
        }
    }

    submethod BUILD( Numeric:$!em = 16 * px,
                     Numeric :$!ex = 12 * px,
                     CSS::Module :$!module = CSS::Module::CSS3.module,
                     Str :$style,
                     :$!delegator = default-delegator(),
                     *@values ) {
        
        %module-metadata{$!module} //= $!module.property-metadata;
        die "module $!module lacks meta-data"
            without %module-metadata{$!module};
        
        self!build-style($_) with $style;
    }

    method !box-value(Str $prop, List $children) is rw {
        
	Proxy.new(
	    FETCH => sub ($) {
                %!values{$prop} //= do {
                    my $n = 0;
                    my @bound;
                    @bound[$n++] := self!item-value($_)
                       for $children.list;
                    @bound
                }
            },
	    STORE => sub ($,$v) {
		# expand and assign values to child properties
		my @v = $v.isa(List) ?? $v.list !! [$v];
		@v[1] //= @v[0];
		@v[2] //= @v[0];
		@v[3] //= @v[1];
		my $n = 0;
		%!values{$_} = @v[$n++]
		    for $children.list;
	    }
        );
    }
            
    method !default($prop) {
        %!default{$prop} //= self.coerce( .<default>[1] )
            with %module-metadata{$!module}{$prop};
    }

    method !item-value(Str $prop) is rw {
        Proxy.new(
            FETCH => sub ($) { %!values{$prop} //= self!default($prop) },
            STORE => sub ($,$v) { %!values{$prop} = $v }
        );
    }

    method property(Str $prop) {
        make-property($!module, $prop) without %module-properties{$!module}{$prop};
        %module-properties{$!module}{$prop};
    }

    method !importance($children) is rw {
        Proxy.new(
            FETCH => sub ($) { [&&] $children.map: { %!important{$_} } },
            STORE => sub ($,Bool $v) {
                %!important{$_} = $v
                    for $children.list;
            });
    }

    method important(Str $prop) is rw {
        with self.property($prop) {
            .box
                ?? self!importance( .children )
                !! %!important{$prop}
        }
    }

    multi method FALLBACK(Str $prop) is rw {
        with %module-metadata{$!module}{$prop} {
            self.property: $prop;
            my &meth =
                .<box>
		    ?? method () is rw { self!box-value($prop, .<children>) }
		    !! method () is rw { self!item-value($prop) }
	
	    self.^add_method($prop,  &meth);
            self."$prop"();
        }
        else {
            nextsame;
        }
    }
}
