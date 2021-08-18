use v6;

#| management class for a set of CSS Properties
class CSS::Properties:ver<0.7.3> {

    =begin pod

    =head2 Synopsis

    =begin code :lang<raku>
    use CSS::Units :pt;
    use CSS::Properties;

    my $style = "color:red !important; padding: 1pt";
    my CSS::Properties $css .= new: :$style;
    say $css.important("color"); # True
    $css.border-color = 'red';

    $css.margin = [5pt, 2pt, 5pt, 2pt];
    $css.margin = 5pt;  # set margin on all 4 sides

    # set text alignment
    $css.text-align = 'right';

    say ~$css; # border-color:red; color:red!important; margin:5pt; padding:1pt; text-align:right;
    =end code

    =head2 Description

    This class manages a list of properties. These are typically parsed
    from the body of a CSS rule-set or from an inline `style` tag.

    =head2 CSS Property Accessors

    CSS Properties provides `rw` accessors for all standard CSS3 properties.

    =item color values are converted to Color objects
    =item other values are converted to strings or numeric, as appropriate
    =item the .type method returns additional type information
    =item box properties are arrays that contain four sides. For example, 'margin' contains 'margin-top', 'margin-right', 'margin-bottom' and 'margin-left';
    =item there are also some container properties that may be accessed directly or via a hash; for example, The 'font' accessor returns a hash containing 'font-size', 'font-family', and other font properties.

    =begin code :lang<raku> 
    use CSS::Properties;

    my CSS::Properties $css .= new: :style("color: orange; text-align: CENTER; margin: 2pt; font: 12pt Helvetica");

    say $css.color.hex;       # (FF A5 00)
    say $css.color.type;      # 'rgb'
    say $css.text-align;      # 'center'
    say $css.text-align.type; # 'keyw' (keyword)

    # access margin-top, directly and through margin container
    say $css.margin-top;      # '2'
    say $css.margin-top.type; # 'pt'
    say $css.margin;          # [2 2 2 2]
    say $css.margin[0];       # '2'
    say $css.margin[0].type;  # 'pt'

    # access font-family directly and through font container
    say $css.font-family;       # 'Helvetica'
    say $css.font-family.type;  # 'ident'
    say $css.font<font-family>; # 'Helvetica;
    =end code

    =item The simplest ways of setting a property is to assign a string value which is parsed as CSS.
    =item Unit values are also recognized. E.g. `16pt`.
    =item Colors can be assigned to color objects
    =item Also the type and value can be assigned as a pair.

    =begin code :lang<raku>
    use CSS::Properties;
    use CSS::Units :pt;
    use Color;
    my CSS::Properties $css .= new;

    # assign to container
    $css.font = "14pt Helvetica";

    # assign to component properties
    $css.font-weight = 'bold'; # string
    $css.line-height = 16pt;   # unit value
    $css.border-color = Color.new(0, 255, 0);
    $css.font-style = :keyw<italic>; # type/value pair

    say ~$css; # font:italic bold 14pt/16pt Helvetica;
    =end code

    =end pod

    use CSS::Module:ver(v0.4.6+);
    use CSS::Module::CSS3;
    use CSS::Writer:ver(v0.2.4+);
    use Color;
    use Color::Conversion;
    use CSS::Module::Property;
    use CSS::Properties::Calculator;
    use CSS::Properties::Property;
    use CSS::Properties::Optimizer :%Punctuation, :&punctuate, :&make-declaration-list;
    use CSS::Units :pt, :Function;
    use Method::Also;
    use NativeCall;
    my enum Colors « :rgb :rgba :hsl :hsla »;

    subset KnownFunction of Str:D where 'local'|'format';

    subset Handling of Str where 'initial'|'inherit';

    my %module-index{CSS::Module};        # per-module objects
    my %module-properties{CSS::Module};   # per-module property attributes

    # contextual variables
    has Any   %!values handles <keys Bool>;    # property values
    has Array %!box;
    has Hash  %!struct;
    has Bool  %!important{Int};
    has Handling %!handling{Int};
    has CSS::Module $.module handles <parse-property property-number property-name alias> = CSS::Module::CSS3.module; # associated CSS module
    has Exception @.warnings;
    has Bool $.warn = True;
    has Array $!properties;
    has CArray $!index;
    has CSS::Properties::Optimizer $!optimizer;
    method optimizer(CSS::Properties:D $css:) handles<optimize> {
        $!optimizer //= CSS::Properties::Optimizer.new: :$css, :$!index;
    }
    has CSS::Properties::Calculator $!calc handles<em ex units computed measure viewport-width viewport-height reference-width>;

    =begin pod
    =head2 Other Methods

    =head3  new
    =begin code :lang<raku>
    method new(
        Str :$style,
        CSS::Properties() :$inherit,
        CSS::Properties() :$copy,
        Str :$units = 'pt',
        Numeric :$em = $inherit.em // 12,
        Numeric :$viewport-width,
        Numeric :$viewport-height,
        Numeric :$reference-width,
        *%props,
    ) returns CSS::Properties
    =end code

    Options:

    =item `Str :$style` CSS property list to parse
    =item `CSS::Properties() :$inherit` Properties to be formally inherited
    =item `CSS::Properties() :$copy` Additional properties to be copied in
    =item `Str :$units` # measurement units, such as 'pt', 'px', 'in', etc
    =item `Numeric :$em = 12` initial font size
    =item `Numeric :$viewport-width` for use as `vw` length units
    =item `Numeric :$viewport-height` for use as `vh` length units
    =item `Numeric :$reference-width` for use in box values
    =item `*%props` - CSS property settings
    =end pod

   submethod TWEAK( Str :$style, List :$ast, :$inherit, CSS::Properties :$copy, :$declarations,
                     :module($), :warn($), :$units = 'pt', # stop these leaking through to %props
                     Numeric :$em = 12pt.scale($units),
                     Numeric :$viewport-width, Numeric :$viewport-height,
                     Numeric :$reference-width = 0,
                     *%props, ) {
        $!index = %module-index{$!module} //= $!module.index
            // die "module {$!module.name} lacks an index";
        $!properties = %module-properties{$!module} //= [];
        $!calc .= new: :css(self), :$units, :$viewport-width, :$viewport-height, :$reference-width;

        my @style = .list with $declarations;
        @style.append: self!parse-style($_) with $style;
        @style.append: .list with $ast;

        my @decls = self!build-declarations(@style);

        with $inherit -> $_ is copy {
            $_ = CSS::Properties.COERCE($_)
                unless .isa(CSS::Properties);
            $!calc.em = .em;
            self.inherit: $_;
        }

        self!set-decls(@decls);
        self!copy($_) with $copy;
        self.set-properties(|%props);
    }

    =begin pod
    =head3 measure
    =begin code :lang<raku>
    # Converts a value to a numeric quantity;
    my Numeric $font-size = $css.measure: :font-size; # get current font size
    $font-size = $css.measure: :font-size<smaller>;   # compute a smaller font
    $font-size = $css.measure: :font-size(120%);      # compute a larger font
    my $weight = $css.measure: :font-weight;          # get current font weight 100..900
    $weight = $css.measure: :font-weight<bold>;       # compute bold font weight
    =end code

    This function is implemented for `font-size`, `font-weight`, `letter-spacing`, `line-height`, and `word-spacing`.

    It also works for box related properties: `width`, `height`, `{min|max}-{width|height}`, `border-{top|right|bottom|left}-width`, and `{padding|margin}-{top|right|bottom|left}`.
The `reference-width` attribute represents the width of a containing element; which needs to set for correct calculation of percentage box related quantities:

    =begin code :lang<raku>
    $css.reference-width = 80pt;
    say $css.measure: :width(75%); # 60
    =end code
    =end pod

    multi method COERCE(Str:D $style) { self.new: :$style }

    my subset ColorAST of Pair where {.key ~~ 'rgb'|'rgba'|'hsl'|'hsla'}
    my subset Keyword  of Pair where {.key ~~ 'keyw'}

    sub make-property(CSS::Module $module, UInt:D $prop-num) {
        my CSS::Module::Property $meta = %module-index{$module}[$prop-num];

        %module-properties{$module}[$prop-num] //= do {
            my %edges;
            with $meta.edges {
                # e.g. margin, comprised of margin-top, margin-right, margin-bottom, margin-left
                my $n = 0;
                for <top left bottom right> -> $side {
                    my $edge := .[$n++];
                    %edges{$side} = make-property($module, $edge);
                }
            }
            CSS::Properties::Property.new( :$prop-num, :$module, :$meta, :%edges );
        }
    }

    #| return module meta-data for a property
    multi method info(Str:D $prop-name --> CSS::Properties::Property) {
        my $prop-num := self.property-number($prop-name)
            // die "unknown property: $prop-name";
        self.info($prop-num);
    }
    multi method info(Int:D $prop-num --> CSS::Properties::Property) {
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
            when $_ ~~ Pair|Hash && (my $p0 := .pairs[0]).key.starts-with('expr:') {
                # embedded property declaration
                @props.push: $p0.key.substr(5) => $p0.value
            }
            when (%Punctuation{$prop-name}:exists) && .<op> eqv %Punctuation{$prop-name} {
                # filter out some punctuation from the api:
                # - '/' operator, as in 'font:10pt/12pt times-roman'
                # - ',' between src arguments
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
        my $actions = $!module.actions.new: :lax;
        $!module.grammar.parse($style, :$rule, :$actions)
            or die "unable to parse CSS style declarations: $style";
        @!warnings = $actions.warnings;
        if $!warn {
            note .message for @!warnings;
        }
        $/.ast.list
    }

    method !build-declarations(@style) {
        my @decls;
        for @style {
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
                            @decls.push: $prop => $expr;
                            self.important($prop) = $_
                                with $important;
                        }
                    }
                }
            }
        }
        @decls;
    }

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

    method !default($_) {
        when /^'border-'[top|right|bottom|left]'-color'$/ {
            self.?color;
        }
        when 'text-align' {
            %!values<direction> && self.direction eq 'rtl' ?? 'right' !! 'left';
        }
        default {
            %!values{$_} //= self!coerce( $.info($_).default-value )
        }
    }

    method !item-value(Str $prop) is rw {
        Proxy.new(
            FETCH => -> $ {
               %!values{$prop} // self!default($prop);
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

    # True if the given property will be inherited
    multi method inherited(Str $prop --> Bool) {
        with $.handling($prop) { $_ ~~ 'inherit' } else { self.info($prop).inherit}
    }
    # Returns all atomic properties that will be inherited
    multi method inherited returns Seq {
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

    #| return True if the property has the !important attribute
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
    #| Return all properties that have the !important attribute
    multi method important {
        %!important.pairs.map: { $.property-name(.key) => .value }
    }

    proto sub from-ast($) is export(:from-ast) {*}
    multi sub from-ast(ColorAST $v) {
        my @channels = $v.value.map: {from-ast($_)};
        my Color $color;
        my $type = $v.key;
        @channels.tail *= 256
            if $type ~~ 'rgba'|'hsla';

        $color .= new: |($type => @channels);

        $color does CSS::Units[Colors, $type];
    }
    multi sub from-ast(Keyword $v) {
        state $cache //= %(
            'transparent' => (Color
                              but CSS::Units[Colors, 'rgba']).new( :r(0), :g(0), :b(0), :a(0));
        );
        $cache{$v.value} //= CSS::Units.value($v.value, $v.key);
    }
    multi sub from-ast(Pair $v) {
        given $v.key {
            when 'func' {
                my $name = $v.value<ident>;
                my @args = $v.value<args>.map: { from-ast($_) };
                if $name ~~ KnownFunction {
                    @args does CSS::Units[Function, $name]
                }
                else {
                    warn "Unknown function: $name\(\)";
                    $v;
                }
            }
            when 'expr' {
                my @expr = $v.value.map: { from-ast($_) };
                CSS::Units.value(@expr, $_);
            }
            default {
                my \r = from-ast( $v.value );
                r ~~ CSS::Units
                    ?? r
                    !! CSS::Units.value(r, $_);
            }
        }
    }
    multi sub from-ast(List $v) {
        $v.elems == 1
            ?? from-ast( $v[0] )
            !! [ $v.map: { from-ast($_) } ];
    }
    # { :int(42) } => :int(42)
    multi sub from-ast(Hash $v where .keys == 1) {
        from-ast( $v.pairs[0] );
    }
    multi sub from-ast($v) {
        $v
    }

    multi sub coerce-str(List $_) {
        .map({ coerce-str($_) // return }).join: ' ';
    }
    multi sub coerce-str($_) {
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
        from-ast(expr);
    }

    #| convert 0 .. 255  =>  0.0 .. 1.0. round to 2 decimal places
    sub alpha($a) {
        :num(($a * 100/256).round / 100);
    }

    proto sub to-ast(|) is export(:to-ast) {*}

    multi sub to-ast(Pair $v) { $v }

    multi sub to-ast($v, :$get = True) is default {
        my $key = $v.?type if $get;

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
            when $key ~~ KnownFunction {
                my $ident := $key;
                $key := 'func';
                my @args = .map: {to-ast($_)};
                %( :$ident, :@args );
            }
            when List  {
                .elems == 1 && $key !~~ 'expr'
                    ?? to-ast( .[0] )
                    !! [ .map: { to-ast($_) } ];
            }
            default {
                $key
                    ?? to-ast($_, :!get)
                    !! $_;
            }
        }

        $key
            ?? ($key => $val)
            !! $val;
    }

    #| CSS conformant inheritance from the given parent declaration list.
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
    =begin pod
    =para Note:
    =item handling of 'initial' and 'inherit' in the child declarations
    =item !important override properties in parent
    =item not all properties are inherited. e.g. color is, margin isn't
    =end pod

    method !copy(CSS::Properties $css) {
        %!values{$_} = $css."$_"()
            for $css.properties;
    }

    method !set-decls(@decls) {
        for @decls -> \p {
            with $.property-number(p.key) {
                self."{p.key}"() = $_ with p.value;
            }
            else {
                warn "unknown {$!module.name} property: {p.key}";
            }
        }
        self;
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
    method clone(*@decls, *%props) {
        my $obj = self.new( :copy(self), :$!module, :$.em, :$.viewport-width, :$.viewport-height, :$.reference-width );
        $obj!set-decls(@decls);
        $obj.set-properties(|%props);
        $obj;
    }

    #| return an AST for the declarations.
    method ast(Bool :$optimize = True, Bool :$keep-defaults) {
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

        # expressions
        for %!values.keys.sort -> \prop {
            with %!values{prop} -> \value {
                my $ast = to-ast(value);
                $ast .= List
                    unless $ast ~~ List;
                %prop-ast{prop}<expr> = $ast;
            }
        }

        self.optimizer.purge-defaults(%prop-ast)
            unless $keep-defaults;

        self.optimizer.optimize-ast(%prop-ast)
            if $optimize;

        punctuate(%prop-ast);
        make-declaration-list(%prop-ast);
    }
    =para This is more-or-less the inverse of the L<CSS::Grammar::CSS3> C<<declaration-list>> rule,
    but with optimization. Suitable for reserialization with CSS::Writer


    #| write a set of declarations.
    method write(Bool :$optimize = True,
                 Bool :$terse = True,
                 Bool :$color-names = True,
                 Bool :$keep-defaults = False,
                 |c) is also<Str gist> {
        my CSS::Writer $writer .= new( :$terse, :$color-names, |c);
        $writer.write: self.ast(:$optimize, :$keep-defaults);
    }
    =para By default, it is formatted as a single-line,
    suited to an HTML inline-style (style attribute).

    #| return the names of all properties
    multi method properties(:$all! where .so) {
        $!index».name;
    }
    #| return the names of in-use properties
    multi method properties {
        %!values.keys.sort;
    }
    #| True if the property has been set
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
    #| returns the value of the named property
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
