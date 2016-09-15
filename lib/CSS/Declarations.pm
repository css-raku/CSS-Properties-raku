use v6;

class CSS::Declarations {

    use CSS::Declarations::Property;
    use CSS::Declarations::Edges;
    use CSS::Declarations::Units;
    use CSS::Module;
    use CSS::Module::CSS3;
    use CSS::Writer;
    use Color;
    my %module-metadata{CSS::Module};     #| per-module metadata
    my %module-properties{CSS::Module};   #| per-module property definitions

    #| contextual variables
    has Any %!values;         #| property values
    has Array %!box;
    has Hash %!struct;
    has Bool %!important;
    has %!default;
    my subset Handling of Str where 'initial'|'inherit';
    has Handling %!handling;
    has CSS::Module $.module; #| associated CSS module
    has @.warnings;

    multi sub make-property(CSS::Module $m, Str $name where { %module-properties{$m}{$name}:exists })  {
        %module-properties{$m}{$name}
    }

    multi sub make-property(CSS::Module $m, Str $name) is default {
        with %module-metadata{$m}{$name} -> %defs {
            with %defs<edges> {
                # e.g. margin, comprised of margin-top, margin-right, margin-bottom, margin-left
                for .list -> $side {
                    # these shouldn't nest or cycle
                    %defs{$side} = $_ with make-property($m, $side);
                }
                %module-properties{$m}{$name} = CSS::Declarations::Edges.new( :$name, |%defs);
            }
            else {
                with %defs<children> {
                    die "compound property not implemented: $name. please use constituant properties: $_";
                }
                else {
                    %module-properties{$m}{$name} = CSS::Declarations::Property.new( :$name, |%defs );
                }
            }
        }
        else {
            die "unknown property: $name"
        }
        %module-properties{$m}{$name};
    }

    method info(Str $prop) {
        with %module-properties{$!module}{$prop} {
            $_;
        }
        else {
            make-property($!module, $prop);
        }
    }

    method !get-props(Str $prop-name, List $expr) {
        my @props;

        my @expr;
        for $expr.list {
            if $_ ~~ Pair|Hash && .keys[0] ~~ /^'expr:'(.*)$/ {
                # embedded property declaration
                @props.push: ~$0 => .values[0]
            }
            else {
                @expr.push: $_;
            }
        }
        @props.push: $prop-name => @expr
            if @expr;

        @props;
    }

    method !build-property($prop, $expr, :$important) {
        my \keyw = $expr[0]<keyw>;
        if keyw ~~ Handling {
            self.handling($prop) = keyw;
        }
        else {
            self."$prop"() = $expr;
            self.important($prop) = $_
                with $important;
        }
    }

    method !build-style(Str $style) {
        my $rule = "declaration-list";
        my $actions = $!module.actions.new;
        $!module.grammar.parse($style, :$rule, :$actions)
            or die "unable to parse CSS style declarations: $style";
        @!warnings = $actions.warnings;
        my @declarations = $/.ast.list;

        for @declarations {
            my \decl = .value;
            given .key {
                when 'property' {
                    with decl<expr> -> \expr {
                        my $important = True
                            if decl<prio> ~~ 'important';

                        self!build-property( .key, .value, :$important)
                            for self!get-props(decl<ident>, expr).list;
                    }
                }
                default {
                    die "ignoring: $_ declaration";
                }
            }
        }
    }

    submethod BUILD( CSS::Module :$!module = CSS::Module::CSS3.module,
                     Str :$style, :$inherit = [], *%props,
                   ) {
        
        %module-metadata{$!module} //= $!module.property-metadata;
        die "module $!module lacks meta-data"
            without %module-metadata{$!module};

        self!build-style($_) with $style;
        self.inherit($_) for $inherit.list;
        for %props.pairs {
            if %module-metadata{$!module}{.key} {
                self."{.key}"() = .value;
            }
            else {
                warn "unknown property/option: {.key}";
            }
        }
    }

    method !box-value(Str $prop, List $edges) is rw {
	Proxy.new(
	    FETCH => sub ($) {
                %!box{$prop} //= do {
                    my $n = 0;
                    my @bound;
                    @bound[$n++] := self!item-value($_)
                        for $edges.list;
                    @bound;
                }
            },
	    STORE => sub ($,$v) {
		# expand and assign values to child properties
		my @v = $v.isa(List) ?? $v.list !! [$v];
		@v[1] //= @v[0];
		@v[2] //= @v[0];
		@v[3] //= @v[1];

		my $n = 0;
		%!values{$_} = self.coerce( @v[$n++], :prop($_) )
                    for $edges.list;
	    }
        );
    }

    method !struct-value(Str $prop, List $children) is rw {
	Proxy.new(
	    FETCH => sub ($) {
                %!struct{$prop} //= do {
                    my $n = 0;
                    my %bound;
                    %bound{$_} := self."$_"()
                        for $children.list;
                    %bound;
                }
            },
	    STORE => sub ($, $rval where Str|Associative) {
                my %vals;
                if $rval ~~ Str {
                    my @props = self!get-props($prop, self.module.parse-property($prop, $rval));
                    %vals{.key} = .value for @props;
                }
                else {
                    %vals = %$rval;
                }

                for $children.list -> $prop {
                    with %vals{$prop}:delete {
                        self."$prop"() = self.coerce($_, :$prop);
                    }
                    else {
                        self.delete($prop);
                    }
	        }
                note "unknown child properties of $prop: {%vals.keys}"
                    if %vals
            }
            );
    }

    method !metadata { %module-metadata{$!module} }
            
    method !default($prop) {
        %!default{$prop} //= self.coerce( .<default>[1] )
            with self!metadata{$prop};
    }

    method !item-value(Str $prop) {
        Proxy.new(
            FETCH => sub ($) {
                %!values{$prop} = self!default($prop)
                    unless %!values{$prop}:exists;
                %!values{$prop};
            },
            STORE => sub ($,$v) { %!values{$prop} = self.coerce( $v, :$prop ) }
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
        with self.info($prop) {
            .edges
                ?? self!child-handling( .edges )
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
        with self.info($prop) {
            .edges
                ?? self!child-importance( .edges )
                !! %!important{$prop}
        }
    }

    my subset ColorAST of Pair where {.key eq 'rgb'|'rgba'|'hsl'|'hsla'}

    multi method from-ast(ColorAST $v) {
        my @channels = $v.value.map: {self.from-ast: $_};
        my Color $color;
        my $type = $v.key;
        @channels[*-1] *= 256
            if $type eq 'rgba'|'hsla';
        if $type eq 'hsla' {
            my Numeric \a = @channels.pop;
            my %rgba = hsl2rgb(@channels);
            %rgba<a> = a;
            $color .= new: |%rgba;
        }
        else {
            $color .= new: |($type => @channels);
        }

        $color does CSS::Declarations::Units::Keyed[$type];
    }
    multi method from-ast(Pair $v) {
        my $r = self.from-ast( $v.value );
        $r does CSS::Declarations::Units::Keyed[$v.key]
            unless $r ~~ CSS::Declarations::Units::Keyed;
        $r
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

    has %!prop-cache; # cache, for performance
    method coerce($val, Str :$prop) {
        my Bool \needs-parse = ? $prop && $val ~~ Str|Numeric && ! $val.can('key');
        my \expr = needs-parse
            ?? (%!prop-cache{$prop}{$val.Str} //= $.module.parse-property($prop, $val.Str))
            !! $val;
        self.from-ast(expr);
    }

    method to-ast($v, :$get = True) {
        my $key = $v.key
            if $v.can('key') && $get;

        my $val = do given $v {
            when Color {
                if .key eq 'hsl' {
                    my (\h, \s, \l) = .hsl;
                    [ :num(h), :percent(s), :percent(l) ];
                }
                elsif .key eq 'hsla' {
                    my (\h, \s, \l) = .hsl;
                    [ :num(h), :percent(s), :percent(l), :num(.a / 256) ];
                }
                elsif .key eq 'rgba' {
                    my (\r, \g, \b, \a) = .rgba;
                    [ :num(r), :num(g), :num(b), :num(a/256) ];
                }
                else {
                     [ $v."$key"().map: -> $num { :$num } ]
                }
            }
            when Pair  { .value }
            when List  { .elems == 1
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

    method inherit(CSS::Declarations $css) {
        for $css.properties -> \name {
            my \info = self.info(name);
            unless info.box {
                my $inherit = False;
                with self.handling(name) {
                    when 'initial' { %!values{name}:delete }
                    when 'inherit' { $inherit = True }
                }
                elsif $css.important(name) {
                    $inherit = True;
                }
                elsif info.inherit {
                    $inherit = True without %!values{name};
                }
                %!values{name} = $css."{name}"()
                    if $inherit;
            }
        }
    }

    my subset ZeroAssoc of Associative where {.values[0] ~~ Numeric && .values[0] =~= 0};
    multi sub same(ZeroAssoc $a, ZeroAssoc $) { $a } # e.g. 0pt :== 0mm
    multi sub same(Associative $a, Associative $b) {$a.pairs.perl eq $b.pairs.perl ?? $a !! False}
    multi sub same($a, $b) is default {$a eqv $b ?? $a !! False}

    # Avoid these serialization optimizations, which won't parse correctly:
    #     font: bold;
    #     font: bold Helvetica;
    # Need a font-size to disambiguate, e.g.: 
    #     font: bold medium Helvetica;
    #     font: medium Helvetica;
    multi method optimizable('font', :@children!
                              where <font-size font-family> ⊈ .Set ) {
        False;
    }

    multi method optimizable(Str $, :@children) is default {
        @children >= 2;
    }

    method !optimize-ast( %prop-ast ) {
        my \metadata = self!metadata;
        my @compound-properties = metadata.keys.sort.grep: { metadata{$_}<children> };
        my %edges;

        for %prop-ast.keys -> \prop {
            # delete properties that match the default value
            my \info = self.info(prop);
            with %prop-ast{prop}<expr> {
                %prop-ast{prop}:delete
                    if +$_ == 1 && same(.[0], info.default-ast[0]);
            }
            %edges{info.edge}++ if info.edge;
        }

        # consolidate box properties with common values
        # margin-right: 1pt; ... margin-bottom: 1pt -> margin: 1pt
        for %edges.keys -> \prop {
            # bottom up aggregation of edges. e.g. border-top-width, border-right-width ... => border-width
            my \info = self.info(prop);
            next unless info.box;
            my @edges = info.edges;
            my @asts = @edges.map: { %prop-ast{$_} };
            # we just handle the simplest case at the moment. Consolidate,
            # if all four properties are present, and have the same value
            if [[&same]] @asts {
                %prop-ast{$_}:delete for @edges;
                %prop-ast{prop} = @asts[0];
            }
        }
        for @compound-properties -> \prop {
            # top-down aggregation of compound properties. e.g. border-width, border-style => border
            
            my @children = metadata{prop}<children>.list.grep: {
                %prop-ast{$_}:exists
            }

            next unless $.optimizable(prop, :@children);

            # take the simple approach of building the compound property, iff
            # all children are consistant
            # -- if child properties are 'initial', or 'inherit', they all
            #    need to be present and the same
            # -- otherwise they need to all need to have or lack
            #    the !important indicator

            my @child-types = @children.map: {
                given %prop-ast{$_} {
                    when .<keyw> ~~ 'initial'|'inherit' {.<keyw>}
                    when .<prio> ~~ 'important' {.<prio>}
                    default { 'normal' }
                }
            }

            if +(@child-types.unique) == 1 {
                # all of the same type
                given @child-types[0] {
                    when 'initial'|'inherit' {
                        if .Num == metadata{prop}<children> {
                            # all child properties need to be present
                            %prop-ast{$_}:delete for @children;
                            %prop-ast{prop} = { expr => [ :keyw($_) ] };
                        }
                    }
                    when 'important'|'normal' {
                        my %ast = expr => [ @children.map: {
                            my \sub-prop = %prop-ast{$_}:delete;
                            'expr:'~$_ => sub-prop<expr>;
                        } ];
                        %ast<prio> = $_
                            when $_ ~~ 'important';
                        %prop-ast{prop} = %ast;
                    }
                }
            }
        }
    }

    method ast(Bool :$optimize = True) {
        my %prop-ast;
        for %!important.keys.grep: { %!important{$_} } {
            %prop-ast{$_}<prio> = 'important';
        }
        for %!handling.keys {
            %prop-ast{$_}<expr> = [ :keyw(%!handling{$_}) ];
        }

        #| find properties with useful values
        for %!values.keys.sort -> \prop {
            with %!values{prop} -> \value {
                my \ast = self.to-ast: value;
                %prop-ast{prop}<expr> = [ ast ];
            }
        }

        self!optimize-ast: %prop-ast
            if $optimize;

        #| assemble property list
        my @declaration-list = %prop-ast.keys.sort.map: -> \prop {
            my %property = %prop-ast{prop};
            %property.push: 'ident' => prop;
            %property;
        };
        
        :@declaration-list;
    }

    method write(Bool :$optimize = True,
                 Bool :$terse = True,
                 Bool :$color-names = True,
                 |c) {
        my \writer = CSS::Writer.new( :$terse, :$color-names, |c);
        writer.write: self.ast(:$optimize);
    }

    method Str { self.write }

    method properties {
        keys %!values;
    }
    method delete(Str $prop) {
        with self!metadata{$prop} {
            if .<box> {
                $.delete($_) for .<edges>.list
            }
            if .<children> {
                $.delete($_) for .<children>.list
            }
            %!values{$prop}:delete;
        }
    }

    multi method FALLBACK(Str $prop) is rw {
        with self!metadata{$prop} {
            my &meth = .<children>
                ?? method () is rw { self!struct-value($prop, .<children>) }
                !! ( .<box>
                     ?? method () is rw { self!box-value($prop, .<edges>) }
	             !! method () is rw { self!item-value($prop) }
                   );
	
	    self.^add_method($prop,  &meth);
            self."$prop"();
        }
    }
}
