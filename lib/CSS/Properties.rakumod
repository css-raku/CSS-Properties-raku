use v6;

#| management class for a set of CSS Properties
class CSS::Properties:ver<0.6.1> {

    use CSS::Module:ver(v0.4.6+);
    use CSS::Module::CSS3;
    use CSS::Writer:ver(v0.2.4+);
    use Color;
    use Color::Conversion;
    use CSS::Module::Property;
    use CSS::Properties::Calculator;
    use CSS::Properties::Property;
    use CSS::Properties::Edges;
    use CSS::Units :pt;
    use Method::Also;
    use NativeCall;
    my enum Colors « :rgb :rgba :hsl :hsla »;

    subset Handling of Str where 'initial'|'inherit';

    my %module-index{CSS::Module};        # per-module objects
    my %module-properties{CSS::Module};   # per-module property attributes

    # contextual variables
    has Any   %!values handles <keys>;    # property values
    has Any   %!default;
    has Array %!box;
    has Hash  %!struct;
    has Bool  %!important{Int};
    has Handling %!handling{Int};
    has CSS::Module $.module handles <parse-property property-number property-name alias> = CSS::Module::CSS3.module; #| associated CSS module
    has Exception @.warnings;
    has Bool $.warn = True;
    has Array $!properties;
    has CArray $!index;
    has CSS::Properties::Calculator $!calc handles<em ex units computed measure viewport-width viewport-height reference-width>;

    my subset ZeroPoint of Associative where {
        # e.g. { :px(0) } === { :mm(0.0) }
        with .values[0] { $_ ~~ Numeric && $_ =~= 0 }
    }
    my subset ColorAST of Pair where {.key ~~ 'rgb'|'rgba'|'hsl'|'hsla'}
    my subset Keyword  of Pair where {.key ~~ 'keyw'}

    multi sub css-eqv(%a, %b) {
        return True if %a ~~ ZeroPoint && %b ~~ ZeroPoint;
	if %a.elems != %b.elems { return False }
        for %a.kv -> $k, $v {
            return False
                unless %b{$k}:exists && css-eqv($v, %b{$k});
	}
	True;
    }
    multi sub css-eqv(@a, @b) {
	if +@a != +@b { return False }
	for @a.kv -> $k, $v {
	    return False
		unless css-eqv($v, @b[$k]);
	}
	True;
    }
    multi sub css-eqv(Numeric:D $a, Numeric:D $b) { $a == $b }
    multi sub css-eqv(Stringy $a, Stringy $b) { $a eq $b }
    multi sub css-eqv(Any $a, Any $b) is default {
        !$a.defined && !$b.defined
    }

    sub make-property(CSS::Module $module, UInt:D $prop-num) {
        my CSS::Module::Property $meta = %module-index{$module}[$prop-num];

        %module-properties{$module}[$prop-num] //= do {
            with $meta.edges {
                # e.g. margin, comprised of margin-top, margin-right, margin-bottom, margin-left
                my $n = 0;
                my %edges;
                for <top left bottom right> -> $side {
                    my $edge := .[$n++];
                    %edges{$side} = make-property($module, $edge);
                }
                CSS::Properties::Edges.new( :$prop-num, :$module, :$meta, |%edges);
            }
            else {
                CSS::Properties::Property.new( :$prop-num, :$module, :$meta );
            }
        }
    }

    #| return module meta-data for a property
    multi method info(Str:D $prop-name) {
        my $prop-num := self.property-number($prop-name)
            // die "unknown property: $prop-name";
        self.info($prop-num);
    }
    multi method info(Int:D $prop-num) {
        with $!properties[$prop-num] {
            $_;
        }
        else {
            make-property($!module, $prop-num);
        }
    }

    method !get-container-prop(Str $prop-name, List $expr) {
        my @props;

        my @expr;
        for $expr.list {
            when $_ ~~ Pair|Hash && .keys[0] ~~ /^'expr:'(.*)$/ {
                # embedded property declaration
                @props.push: ~$0 => .values[0]
            }
            when $prop-name eq 'font' && .<op> eqv '/' {
                # filter out '/' operator, as in 'font:10pt/12pt times-roman'
            }
            default {
                @expr.push: $_;
            }
        }

        @props.push: $prop-name => @expr
            if @expr;

        @props;
    }

    method !parse-style(Str $style) {
        my $rule = "declaration-list";
        my $actions = $!module.actions.new;
        $!module.grammar.parse($style, :$rule, :$actions)
            or die "unable to parse CSS style declarations: $style";
        @!warnings = $actions.warnings;
        if $!warn {
            note .message for @!warnings;
        }
        $/.ast.list
    }

    method !build-declarations(@declarations) {
        my %props;
        for @declarations {
            with .<property> -> \decl {
                with decl<expr> -> \expr {
                    my $important = True
                        if decl<prio> ~~ 'important';

                    for self!get-container-prop(decl<ident>, expr).list {
                        my $prop := .key;
                        my $expr := .value;
                        my $keyw := $expr[0]<keyw>;
                        if $keyw ~~ Handling {
                            self.handling($prop) = $keyw;
                        }
                        else {
                            %props{$prop} = $expr;
                            self.important($prop) = $_
                                with $important;
                        }
                    }
                }
            }
        }
        %props;
    }

    submethod TWEAK( Str :$style, List :$ast, :$inherit, CSS::Properties :$copy, :$declarations,
                     :module($), :warn($), :$units = 'pt', # stop these leaking through to %props
                     Numeric :$em = 12pt.scale($units),
                     Numeric :$viewport-width, Numeric :$viewport-height,
                     Numeric :$reference-width = 0,
                     *%props, ) {
        $!index = %module-index{$!module} //= $!module.index
            // die "module {$!module.name} lacks an index";
        $!properties = %module-properties{$!module} //= [];
        my @declarations = .list with $declarations;
        @declarations.append: self!parse-style($_) with $style;
        @declarations.append: .list with $ast;
        $!calc .= new: :css(self), :$units, :$viewport-width, :$viewport-height, :$reference-width;

        my %decls = self!build-declarations(@declarations);
        with $inherit -> $_ is copy {
            $_ = CSS::Properties.COERCE($_)
                unless .isa(CSS::Properties);
            $!calc.em = .em;
            self.inherit: $_;
         }
        self.set-properties(|%decls);
        self!copy($_) with $copy;
        self.set-properties(|%props);
    }

    multi method COERCE(Str:D $style) { self.new: :$style }

    method !box-value(Str $prop, CArray $edges) is rw {
	Proxy.new(
	    FETCH => -> $ {
                %!box{$prop} //= do {
                    my $n = 0;
                    my @bound;
                    @bound[$n++] := self!item-value($_)
                        for $edges.list;
                    @bound;
                }
            },
	    STORE => -> $, $v {
                with $v {
                    # expand and assign values to child properties
                    my @v = .isa(List) ?? .list !! $_;
                    @v[1] //= @v[0];
                    @v[2] //= @v[0];
                    @v[3] //= @v[1];

                    my $n = 0;
                    for $edges.list -> $prop {
                        %!values{$prop} = $_
                            with self!coerce( @v[$n++], :$prop )
                    }
                }
                else {
                    self.delete($prop);
                }
	    }
        );
    }

    method !struct-value(Str $prop, CArray $children) is rw {
	Proxy.new(
	    FETCH => -> $ {
                %!struct{$prop} //= do {
                    my $n = 0;
                    my %bound;
                    %bound{$_} := self."$_"()
                        for $children.list;
                    %bound;
                }
            },
	    STORE => -> $, $rval {
                my %vals;
                with $rval {
                    when Associative { %vals = .Hash; }
                    default {
                        with self.parse-property($prop, $_, :$!warn) -> $expr {
                            %vals{.key} = .value
                                for self!get-container-prop($prop, $expr);
                        }
                    }
                }
                else {
                    self.delete($prop);
                }

                for $children.list -> $prop {
                    with %vals{$prop}:delete {
                        self."$prop"() = $_
                            with self!coerce($_, :$prop);
                    }
                    else {
                        self.delete($prop);
                    }
	        }
                note "unknown child properties of $prop: {%vals.keys.sort}"
                    if %vals
            }
            );
    }

    #| return the default value for the property
    method !default($prop) {
        %!default{$prop} //= self!coerce( .default-value )
            with $.info($prop);
    }

    method !item-value(Str $prop) is rw {
        Proxy.new(
            FETCH => -> $ {
                with %!values{$prop} {
                    $_
                }
                elsif $prop ~~ /^'border-'[top|right|bottom|left]'-color'$/ {
                    self.?color;
                }
                elsif $prop eq 'text-align' {
                    %!values<direction> && self.direction eq 'rtl' ?? 'right' !! 'left';
                }
                else {
                    %!values{$prop} = self!default($prop)
                }
            },
            STORE => -> $, $v {
                with self!coerce( $v, :$prop ) {
                    $!calc.em = self.measure(:font-size($_))
                        if $prop eq 'font-size';
                    %!values{$prop} = $_;
                }
                else {
                    self.delete($prop);
                }
            }
        );
    }

    method !child-handling(CArray $children) is rw {
        Proxy.new(
            FETCH => -> $ { [&&] $children.map: { %!handling{$_} } },
            STORE => -> $, Str $h {
                %!handling{$_} = $h
                    for $children.list;
            });
    }

    #| return property value handling: 'initial', or 'inherit';
    multi method handling(Str:D $prop --> Handling) is rw {
        self.handling(self.property-number($prop));
    }
    multi method handling(Int:D $prop --> Handling) is rw {
        with self.info($prop) {
            with .edges {
                self!child-handling( $_ );
            }
            else {
                %!handling{$prop};
            }
        }
    }

    multi method inherited(Str $prop) {
        with $.handling($prop) { $_ ~~ 'inherit' } else { self.info($prop).inherit}
    }
    multi method inherited {
        %!values.keys.grep({ $.inherited($_) }).sort;
    }

    method !child-importance(CArray $children) is rw {
        Proxy.new(
            FETCH => -> $ { [&&] $children.map: { %!important{$_} } },
            STORE => -> $, Bool $v {
                %!important{$_} = $v
                    for $children.list;
            });
    }

    #| return true of the property has the !important attribute
    multi method important(Str $prop-name) is rw { self.important($.property-number($prop-name)) }
    multi method important(Int $prop-num) is rw {
        with self.info($prop-num) {
            with .edges {
                self!child-importance( $_ );
            }
            else {
                %!important{$prop-num};
            }
        }
    }
    multi method important is default {
        %!important.pairs.map: { $.property-name(.key) => .value }
    }

    multi method from-ast(ColorAST $v) {
        my @channels = $v.value.map: {self.from-ast: $_};
        my Color $color;
        my $type = $v.key;
        @channels.tail *= 256
            if $type ~~ 'rgba'|'hsla';

        $color .= new: |($type => @channels);

        $color does CSS::Units[Colors, $type];
    }
    multi method from-ast(Keyword $v) {
        state $cache //= %(
            'transparent' => (Color
                              but CSS::Units[Colors, 'rgba']).new( :r(0), :g(0), :b(0), :a(0));
        );
        $cache{$v.value} //= CSS::Units.value($v.value, $v.key);
    }
    multi method from-ast(Pair $v) {
        my \r = self.from-ast( $v.value );
        r ~~ CSS::Units
            ?? r
            !! CSS::Units.value(r, $v.key);
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

    multi sub coerce-str(List $_) {
        .map({ coerce-str($_) // return }).join: ' ';
    }
    multi sub coerce-str($_) is default {
        .Str if $_ ~~ Str|Numeric && ! .can('type');
    }
    has %!ast-cache{Str}; # cache, for performance
    method !coerce($val, Str :$prop) {
        my \expr = do with $prop && coerce-str($val) {
            (%!ast-cache{$prop}{$_} //= $.parse-property($prop, $_, :$!warn))
        }
        else {
            $val;
        }
        self.from-ast(expr);
    }

    #| convert 0 .. 255  =>  0.0 .. 1.0. round to 2 decimal places
    sub alpha($a) {
        :num(($a * 100/256).round / 100);
    }

    multi method to-ast(Pair $v) { $v }

    multi method to-ast($v, :$get = True) is default {
        my $key = $v.?type if $get;
        my @ast;
        my $val = do given $v {
            when Color {
                $key //= 'rgb';
                my $ast := $key ~~ 'hsl'|'hsla'
                    ?? [ <num percent percent> Z=> $v.hsl ]
                    !! [ <num num num> Z=> $v.rgb ];
                $ast.push( alpha($v.a) )
                    if $key ~~ 'rgba'|'hsla';
                $ast;
            }
            when List  {
                .elems == 1
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

    #| CSS conformant inheritance from the given parent declaration list. Note:
    #| - handling of 'initial' and 'inherit' in the child declarations
    #| - !important override properties in parent
    #| - not all properties are inherited. e.g. color is, margin isn't

    multi method inherit(CSS::Properties:D() $css) {
        for $css.properties -> \name {
            # skip unknown extension properties
            next if name.starts-with('-') && !self.prop-num(name).defined;
            my \info = self.info(name);
            unless info.box {
                my $inherit = False;
                my $important = False;
                with self.handling(name) {
                    when 'initial' { %!values{name}:delete }
                    when 'inherit' { $inherit = !(%!values{name}:exists) }
                }
                elsif info.inherit {
                    $inherit = True without %!values{name};
                }
                if $inherit {
                    %!values{name} = $css.computed(name);
                }
            }
        }
        self;
    }

    method !copy(CSS::Properties $css) {
        %!values{$_} = $css."$_"()
            for $css.properties;
    }

    #| set a list of properties as hash pairs
    method set-properties(*%props) {
        for %props.pairs.sort -> \p {
            with $.property-number(p.key) {
                self."{p.key}"() = $_ with p.value;
            }
            else {
                warn "unknown property/option: {p.key}";
            }
        }
        self;
    }

    #| create a deep copy of a CSS declarations object
    method clone(*%props) {
        my $obj = self.new( :copy(self), :$!module, :$.em, :$.viewport-width, :$.viewport-height, :$.reference-width );
        $obj.set-properties(|%props);
        $obj;
    }

    #| determine if it is advantageous to combine component properties
    #| into container properties, e.g. font-family font-style ... into font
    proto sub optimizable(Str $cont-prop, :%props) { * }

    # Avoid these font serialization optimizations, which won't parse correctly:
    #     font: bold;            // font-weight or font-style only
    #     font: bold Helvetica;  // ... + family-name
    # Need a font-size or font-family to disambiguate, e.g.:
    #     font: bold medium Helvetica;
    #     font: medium Helvetica;
    multi method optimizable('font', :%props (:$font-size, :$font-family, |c) ) {
        $font-size.defined && $font-family.defined;
    }

    # only worthwhile, if there's more than one component
    multi method optimizable(Str $, :%props) is default {
        %props.elems >= 2;
    }

    method optimize( @ast ) {
        my %prop-ast;
        for @ast.grep(*.key eq 'property') {
            my %v = .value;
            %prop-ast{$_} = %v
                with %v<ident>:delete;
        }

        self!optimize-ast(%prop-ast);
        tweak-ast(%prop-ast);
        assemble-ast(%prop-ast);
    }

    has Array $!container-properties;
    method !container-properties {
        $!container-properties //= [$!index.grep(*.children).map(*.name)];
    }

    method !optimize-ast( %prop-ast ) {
        my %edges{Int};

        for %prop-ast.keys.sort -> \prop {
            # delete properties that match the default value
            my \info = self.info(prop);

            with %prop-ast{prop}<expr> -> \val {
                %prop-ast{prop}:delete
                    if css-eqv(val[0], info.default-value[0]);
            }
            %edges{info.edge}++ if info.edge;
        }

        # consolidate box properties with common values
        # margin-right: 1pt; ... margin-bottom: 1pt -> margin: 1pt
        for %edges.keys.sort -> Int $prop {
            # bottom up aggregation of edges. e.g. border-top-width, border-right-width ... => border-width
            my \info = self.info($prop);
            next unless info.box;
            my @edges;
            my @asts;
            for info.edges -> \side {
                my $prop := self.property-name(side);
                with %prop-ast{$prop} {
                    @edges.push: $prop;
                    @asts.push: $_;
                }
                else {
                    last;
                }
            }

            if @asts > 1 && @asts.map( *<prio> ).unique == 1 {
                # consecutive edges present at the same priority; consolidate
                %prop-ast{$_}:delete for @edges;

                my constant DefaultIdx = [Mu, Mu, 0, 0, 1];
                @asts.pop
                    while +@asts > 1
                    && css-eqv( @asts.tail, @asts[ DefaultIdx[+@asts] ] );

                my @expr = flat @asts.map(*<expr>.list);

                my $name = self.property-name($prop);
                %prop-ast{$name} = { :@expr };
                %prop-ast{$name}<prio> = $_
                    with @asts[0]<prio>;
            }
        }
        for self!container-properties.list -> \container-prop {
            # top-down aggregation of container properties. e.g. border-width, border-style => border

            my @children = $.info(container-prop).child-names.grep: {
                %prop-ast{$_}:exists
            }

            my %props = %(@children.Set);
            next unless @children && $.optimizable(container-prop, :%props);

            # agregrate related children to a container property, where possible.
            # -- if child properties are 'initial', or 'inherit', they all
            #    need to be present and the same
            # -- otherwise they need to all need to have or lack
            #    the !important indicator

            my %groups = @children.classify: {
                given %prop-ast{$_} {
                    when .<expr>.elems > 1              # complex expression
                    || .<expr>[0]<keyw> ~~ Handling  {  # 'initial', or 'inherit'
                        'omit'
                    }
                    when .<prio> ~~ 'important' {'important'}
                    default {'normal'}
                }
            }

            %groups<omit>:delete;

            #| find largest consolidation group
            my $group = do with %groups.pairs.sort(*.key).sort({+.value}).tail {
                .key
                    if + .value > 1;
            }

            with $group {
                # all of the same type
                given %groups{$_}.list -> @children {
                    when Handling {
                        %prop-ast{$_}:delete for @children;
                        %prop-ast{container-prop} = { :expr[ :keyw($_) ] };
                    }
                    when 'important'|'normal' {
                        my %ast = :expr[ @children.map: {
                            my \sub-prop = %prop-ast{$_}:delete;
                            'expr:'~$_ => sub-prop<expr>;
                        } ];
                        %ast<prio> = $_
                            when 'important';
                        %prop-ast{container-prop} = %ast;
                    }
                }
            }
        }
        %prop-ast;
    }

    multi sub tweak-ast(% ( :%font! ( :$expr! is rw ))) {
        # reinsert font '/' operator if needed...
        # e.g.: font: italic bold 10pt/12pt times-roman;
        $_ = [ flat .map: { .key eq 'expr:line-height' ?? [ :op('/'), $_, ] !! $_ } ]
            given $expr;
    }
    multi sub tweak-ast(%) is default {
        # nothing to do
    }

    #| assemble property list
    multi sub assemble-ast(%prop-ast) {
        my @declaration-list = %prop-ast.keys.sort.map: -> \prop {
            my %property = %prop-ast{prop};
            %property<ident> = prop;
            %property;
        };

        :@declaration-list;
    }

    #| return an AST for the declarations.
    #| This is more-or-less the inverse of CSS::Grammar::CSS3::declaration-list>,
    #| but with optimization. Suitable for reserialization with CSS::Writer
    method ast(Bool :$optimize = True) {
        my %prop-ast;
        # '!important'
        for %!important.pairs {
            %prop-ast{$.property-name(.key)}<prio> = 'important'
                if .value;
        }
        # 'initial', 'inherit'
        for %!handling.pairs {
            %prop-ast{$.property-name(.key)}<expr> = [ :keyw(.value) ]
                if .value;
        }

        #| expressions
        for %!values.keys.sort -> \prop {
            with %!values{prop} -> \value {
                my $ast = self.to-ast: value;
                $ast .= List
                    unless $ast ~~ List;
                %prop-ast{prop}<expr> = $ast;
            }
        }

        self!optimize-ast(%prop-ast)
            if $optimize;

        tweak-ast(%prop-ast);
        assemble-ast(%prop-ast);
    }

    #| write a set of declarations. By default, it is formatted as a single-line,
    #| suited to an HTML inline-style (style attribute).
    method write(Bool :$optimize = True,
                 Bool :$terse = True,
                 Bool :$color-names = True,
                 |c) is also<Str gist> {
        my CSS::Writer $writer .= new( :$terse, :$color-names, |c);
        $writer.write: self.ast(:$optimize);
    }

    #| return all known module properties
    multi method properties(:$all! where .so) {
        $!index.map(*.name);
    }
    #| return in-use properties
    multi method properties {
        %!values.keys.sort;
    }
    method property-exists(Str $_) { %!values{.lc}:exists }

    #| delete property values from the list of populated properties
    method delete(*@props) {
        for @props -> Str $prop {
            with $.info($prop) {
                if .box {
                    $.delete($_) for .edge-names;
                }
                with .child-names {
                    $.delete($_) for $_;
                }
            }
            %!values{$prop}:delete;
        }
        self;
    }

    method dispatch:<.?>(\name, |c) is raw {
        self.can(name)
            ?? self."{name}"(|c)
            !! do with $.propertry-number(name) { self!value($!index[$_], name, |c) } else { Nil }
    }
    method !value($_, \name, |c) is rw {
        .children
            ?? self!struct-value(name, .child-names)
            !! ( .box
                     ?? self!box-value(name, .edge-names)
                     !! self!item-value(name)
                    )
    }
    method property(Str \name) is rw {
        with $.property-number(name) {
            self!value($!index[$_], name)
        }
        else {
            fail "unknown property: {name}";
        }
    }
    method FALLBACK(Str \name, |c) is rw {
        with $.property-number(name) {
            self!value($!index[$_], name, |c)
        }
        else {
            die X::Method::NotFound.new( :method(name), :typename(self.^name) )
        }
    }
}
