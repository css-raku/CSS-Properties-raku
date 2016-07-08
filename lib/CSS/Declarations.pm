use v6;

class CSS::Declarations {

    use CSS::Declarations::Property;
    use CSS::Declarations::Box;
    use CSS::Declarations::Units;
    use CSS::Module;
    use CSS::Module::CSS3;
    use CSS::Writer;
    my %module-metadata{CSS::Module};     #| per-module metadata
    my %module-properties{CSS::Module};   #| per-module property definitions

    #| contextual variables
    has Any %!values          #| property values
        handles <keys>;
    has Bool %!important;
    has %!default;
    my subset Handling of Str where 'initial'|'inherit';
    has Handling %!handling;
    has CSS::Module $!module; #| associated CSS module
    has @.warnings;

    multi sub make-property(CSS::Module $m, Str $name where { %module-properties{$m}{$name}:exists })  {
        %module-properties{$m}{$name}
    }

    multi sub make-property(CSS::Module $m, Str $name) is default {
        with %module-metadata{$m}{$name} -> %defs {
            with %defs<children> {
                # e.g. margin, comprised of margin-top, margin-right, margin-bottom, margin-left
                for .list -> $side {
                    # these shouldn't nest or cycle
                    %defs{$side} = $_ with make-property($m, $side);
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
        %module-properties{$m}{$name};
    }

    method property(Str $prop) {
        with %module-properties{$!module}{$prop} {
            $_;
        }
        else {
            make-property($!module, $prop);
        }
    }

    method !get-props($decl) {
        my $prop-name = $decl<ident>;
        my @props;

        with $decl<expr> {
            my @expr;
            for .list {
                if $_ ~~ Pair|Hash && .keys[0] ~~ /^'expr:'(.*)$/ {
                    # embedded property declaration
                    @props.push: $0 => .values[0]
                }
                else {
                    @expr.push: $_;
                }
            }
            @props.push: $prop-name => @expr
                if $prop-name && @expr;
        }
        @props;
    }

    method !build-style(Str $style) {
        my $rule = "declaration-list";
        my $actions = $!module.actions.new;
        $!module.grammar.parse($style, :$rule, :$actions)
            or die "unable to parse CSS style declarations: $style";
        @!warnings = $actions.warnings;
        my @declarations = $/.ast.list;

        for @declarations {
            my $decl = .value;
            given .key {
                when 'property' {
                    my @props = self!get-props($decl);
                    for @props {
                        my $prop = .key;
                        my $expr = .value;
                        my $keyw = $expr[0]<keyw>;
                        if $keyw ~~ Handling {
                            self.handling($prop) = $keyw;
                        }
                        else {
                            self."$prop"() = $expr;
                            self.important($prop) = True
                                if $decl<prio>;
                        }
                    }
                }
                default {
                    die "ignoring: $_ declaration";
                }
            }
        }
    }

    my subset ListOrStr of Any where List|Str;

    submethod BUILD( CSS::Module :$!module = CSS::Module::CSS3.module,
                     ListOrStr :$style = [],
                     :$inherit = [],
                   ) {
        
        %module-metadata{$!module} //= $!module.property-metadata;
        die "module $!module lacks meta-data"
            without %module-metadata{$!module};

        with $style {
            when List {
                self."{.key}"() = .value
                for .list;
            }
            default { self!build-style($_) }
        }
        self.inherit($_) for $inherit.list;
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
		%!values{$_} = self.coerce: @v[$n++]
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
            FETCH => sub ($) { %!values{$prop} // self!default($prop) },
            STORE => sub ($,$v) { %!values{$prop} = self.coerce: $v }
        );
    }

    method !child-handling(List $children) is rw {
        Proxy.new(
            FETCH => sub ($) { [&&] $children.map: { %!handling{$_} } },
            STORE => sub ($,Str $h) {
                %!handling{$_} = $h
                    for $children.list;
            });
    }

    method handling(Str $prop) is rw {
        with self.property($prop) {
            .children
                ?? self!child-handling( .children )
                !! %!handling{$prop}
        }
    }

    method !child-importance(List $children) is rw {
        Proxy.new(
            FETCH => sub ($) { [&&] $children.map: { %!important{$_} } },
            STORE => sub ($,Bool $v) {
                %!important{$_} = $v
                    for $children.list;
            });
    }

    method important(Str $prop) is rw {
        with self.property($prop) {
            .children
                ?? self!child-importance( .children )
                !! %!important{$prop}
        }
    }

    multi method from-ast(Pair $v) {
        self.from-ast( $v.value )
            does CSS::Declarations::Units::Keyed[$v.key];
    }
    multi method from-ast(List $v) {
        $v.elems == 1
            ?? self.from-ast( $v[0] )
            !! [ $v.map: { self.from-ast($_) } ];
    }
    #| { :int(42) } => :int(42)
    multi method from-ast(Hash $v where .keys == 1) {
        self.from-ast( $v.pairs[0] );
    }
    multi method from-ast($v) is default {
        $v
    }

    method coerce($v) {
        self.from-ast($v);
    }

    method to-ast($v, :$get = True) {
        my $key = $v.key
            if $v.can('key') && $get;

        my $val = do given $v {
            when Pair {.value}
            when List { .elems == 1
                        ?? self.to-ast( .[0] )
                        !! [ .map: { self.to-ast($_) } ];
                      }
            default {
                $key
                    ?? self.to-ast($_, :!get)
                    !! $_;
            }
        }

        $key
            ?? ($key => $val)
            !! $val;
    }

    multi method xxto-ast(Pair $v) {
        $v.key => self.to-ast($v.value);
    }
    multi method xxto-ast($v where .can('key') , :$skip where not *.so) {
        $v.key => self.to-ast($v, :skip);
    }
    multi method xxto-ast(List $v) {
        $v.elems == 1
            ?? self.to-ast( $v[0] )
            !! [ $v.map: { self.to-ast($_) } ];
    }
    multi method xxto-ast($v) is default {
        $v;
    }

    method inherit(CSS::Declarations $css) {
        for $css.keys -> $name {
            my $info = self.property($name);
            unless $info.box {
                with self.handling($name) {
                    when 'initial' { %!values{$name}:delete }
                    when 'inherit' { %!values{$name} = $css."$name"() }
                }
                elsif $css.important($name) {
                    %!values{$name} = $css."$name"()
                }
                elsif $info.inherit {
                    %!values{$name} //= $css."$name"()
                }
            }
        }
    }

    method !optimize-ast( %prop-ast ) {
        for %prop-ast.keys -> $prop {
            # delete properties that match the default value
            my $info = self.property($prop);
            with %prop-ast{$prop}<expr> {
                %prop-ast{$prop}:delete
                    if +$_ == 1 && .[0] eqv $info.default-ast;
            }
        }
        # consolidate box properties with common values
        # margin-right: 1pt; ... margin-bottom: 1pt -> margin: 1pt
        my %edges;
        for %prop-ast.keys -> $prop {
            my $info = self.property($prop);
            %edges{$info.parent}++ if $info.parent;
        }
        for %edges.keys -> $prop {
            my $info = self.property($prop);
            next unless $info.box;
            my @children = $info.children;
            my @asts = @children.map: { %prop-ast{$_} };
            # we just handle the simplest case at the moment. Consolidate,
            # if all four properties are present, and have the same value
            # todo: should be eqv
            if [eq] @asts {
                %prop-ast{$_}:delete for @children;
                %prop-ast{$prop} = @asts[0];
            }
        }
        # todo: further consolidation
        # border-color: red; bother-width: 1pt => border: 1pt red;
    }

    method ast {
        my %parents;
        my %prop-ast;
        for %!important.keys.grep: { %!important{$_} } {
            %prop-ast{$_}<prio> = 'important';
        }
        for %!handling.keys {
            %prop-ast{$_}<expr> = [ :keyw(%!handling{$_}) ];
        }

        #| find properties with useful values
        for %!values.keys.sort -> $prop {
            my $ast = self.to-ast: %!values{$prop};
            %prop-ast{$prop}<expr> = [ $ast ];
        }

        self!optimize-ast: %prop-ast;

        #| assemble property list
        my @declaration-list = %prop-ast.keys.sort.map: -> $prop {
            my %ast = %prop-ast{$prop};
            %ast.push: 'ident' => $prop;
            %ast;
        };
        
        # todo: consolidation of identical box properties;
        :@declaration-list;
    }

    method write {
        my $writer = CSS::Writer.new: :terse;
        $writer.write: self.ast;
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
            die "uknown property/method: $_";
        }
    }
}
