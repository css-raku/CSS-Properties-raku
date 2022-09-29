use v6;

#| management class for a set of CSS Properties
class CSS::Properties:ver<0.9.5>:api<0.9> {

    =begin pod

    =head2 Synopsis

    =begin code :lang<raku>
    use CSS::Units :pt;
    use CSS::Properties;

    my CSS::Properties() $css = "color:red !important; padding: 1pt";
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
    use CSS::Properties::PropertyInfo;
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
    has Any   %!values handles <keys>;    # property values
    has Any   %!defaults;
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
    method optimizer(::?CLASS:D $css:) handles<optimize> {
        $!optimizer //= CSS::Properties::Optimizer.new: :$css, :$!index;
    }
    has CSS::Properties::Calculator $!calc handles<em ex units computed measure viewport-width viewport-height reference-width>;
    my Lock:D $lock .= new;

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

     submethod TWEAK( Str :$style, List() :$ast, :$inherit, ::?CLASS :$copy,
                     List() :$declarations,
                     Str :$units = 'pt',
                     Numeric :$em = 12pt.scale($units),
                     Numeric :$viewport-width, Numeric :$viewport-height,
                     Numeric :$reference-width = 0,
                     Numeric :$user-width = 1.0,
                     :module($), :warn($), :warnings($),
                     *%props, ) {
        $lock.protect: {
            $!index = %module-index{$!module} //= $!module.index
                // die "module {$!module.name} lacks an index";
            $!properties //= (%module-properties{$!module} //= []);
        }
        $!calc .= new: :css(self), :$units, :$viewport-width, :$viewport-height, :$reference-width, :$user-width;

        my @style = .list with $declarations;
        @style.append: self!parse-style($_) with $style;
        @style.append: .list with $ast;

        my @decls = self!build-declarations(@style);
        with $inherit -> CSS::Properties() $_ {
            $!calc.em = .em;
            self.inherit: $_;
        }

        self!set-decls(@decls);
        self.copy($_) with $copy;
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
    multi method COERCE(%opts) { self.new: |%opts; }

    my subset ColorAST of Pair where {.key ~~ 'rgb'|'rgba'|'hsl'|'hsla'}
    my subset Keyword  of Pair where {.key ~~ 'keyw'}

    # make or reuse a cached property definition 
    sub make-property(CSS::Module $module, UInt:D $prop-num) {
        $lock.protect: {
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
                CSS::Properties::PropertyInfo.new( :$prop-num, :$module, :$meta, :%edges );
            }
        }
    }

    #| return module meta-data for a property
    multi method info(Str:D $prop-name --> CSS::Properties::PropertyInfo) {
        my $prop-num := self.property-number($prop-name)
            // die "unknown property: $prop-name";
        self.info($prop-num);
    }
    multi method info(Int:D $prop-num --> CSS::Properties::PropertyInfo) {
        $!properties[$prop-num] // make-property($!module, $prop-num);
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
                        if self.property-number(.key).defined {
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
                        else {
                            note "dropping unknown {$!module.name} property {.key}"
                        }
                    }
                }
            }
        }
        @decls;
    }

    # Accessor for a four sided value: top, left, bottom, right
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

    # accessor for a structured property. e.g. font -> font-name, style...
    method !struct-value(Str $prop, CArray $children) is rw {
	Proxy.new(
	    FETCH => -> $ {
                %!struct{$prop} //= do {
                    my $n = 0;
                    my %bound;
                    %bound{$_} := self!lval($_)
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
                        self!lval($prop) = $_
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

    # get the default for this property.
    method !default-value($_) {
        when .starts-with('border-') && .ends-with('-color') {
            # border colors default to the 'color' property
            self.?color;
        }
        when 'text-align' {
            # text alignment depends on current direction
            %!values<direction> ~~ 'rtl' ?? 'right' !! 'left';
        }
        default {
            # consult property metadata for other defaults
            %!defaults{$_} //= self!coerce( $.info($_).default-value )
        }
    }

    # accessor for a simple value
    method !item-value(Str $prop) is rw {
        Proxy.new(
            FETCH => -> $ {
               %!values{$prop} // self!default-value($prop);
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

    method !handling() { %!handling }
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
        if $type ~~ 'rgba'|'hsla' {
            @channels.tail /= 100
                if @channels.tail.type ~~ 'percent';
            @channels.tail *= 256;
        }

        $color .= new: |($type => @channels);

        $color does CSS::Units[Colors, $type];
    }
    multi sub from-ast(Keyword $v) {
        $lock.protect: {
            state $cache //= %(
                'transparent' => (
                    Color but CSS::Units[Colors, 'rgba']).new( :r(0), :g(0), :b(0), :a(0));
            );
            $cache{$v.value} //= CSS::Units.value($v.value, $v.key);
        }
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
        $v.elems == 1 && !$v[0]<expr>
            ?? from-ast $v[0]
            !! [ $v.map: { from-ast($_) } ];
    }
    # { :int(42) } => :int(42)
    multi sub from-ast(Hash $v where .keys == 1) {
        from-ast $v.pairs[0];
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
            $lock.protect: {(%!ast-cache{$prop}{$_} //= $.parse-property($prop, $_, :$!warn))}
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
                    unless $v.a == 255;
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
                    %!values{name} //= $css.computed(name);
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

    multi method copy(::?CLASS:U: ::?CLASS:D $orig,  :@properties = [$orig.properties], |c) {
        my $em = $orig.em;
        my $viewport-width  = $orig.viewport-width;
        my $viewport-height = $orig.viewport-height;
        my $reference-width = $orig.reference-width;
        my $obj = self.new: :$em, :$viewport-width, :$viewport-height, :$reference-width, |c;
        $obj.copy: $orig, :@properties;
    }

    multi method copy(::?CLASS:D: ::?CLASS:D $orig, :@properties = [$orig.properties]) {
        for @properties {
            %!values{$_} = $orig."$_"()
                if $.property-number($_).defined;
        }
        for $orig!handling.pairs {
            %!handling{.key} = .value
                if $.property-name(.key).defined;
        }
        self
    }

    method !coerce-decl(&coercer, Pair \p --> Bool) {
        try {
            p.value = coercer from-ast(p.value);
            p.value.so; # trigger any failures
        }
        with $! {
            if $!warn {
                my $message = "usage: " ~ $_
                    with self.info(p.key).synopsis;
                $message //= $!.message;
                note "dropping {$!module.name} property {p.key}: {$message}"
            }
            False;
        }
        else {
            True;
        }
    }

    method !set-decls(@decls) {
        my %coerce := $!module.coerce;
        my CSS::Writer $writer .= new;
        for @decls -> \p {
            with $.property-number(p.key) {
                with %coerce{p.key} {
                    next unless self!coerce-decl($_, p);
                }
                self!lval(p.key, $_) = p.value;
            }
            else {
                note "dropping unknown {$!module.name} property: {p.key}";
            }
        }
        self;
    }
    #| set a list of properties as hash pairs
    method set-properties(*%props) {
        for %props.pairs.sort -> \p {
            with $.property-number(p.key) {
                self!lval(p.key, $_) = p.value;
            }
            else {
                warn "unknown property/option: {p.key}"
                    unless self.can(p.key);
            }
        }
        self;
    }

    method clone(::?CLASS:D $copy: *@decls,
                 :$module=$!module, :$em=$.em, :$viewport-width=$.viewport-width,
                 :$viewport-height=$.viewport-height, :$reference-width=$.reference-width,
                 :$units=$.units,
                 *%props
                --> ::?CLASS:D) {
        my $obj = self.new( :$copy, :$module, :$em, :$viewport-width, :$viewport-height, :$reference-width, :$units );
        $obj!set-decls(@decls);
        $obj.set-properties(|%props);
        $obj;
    }
    =head2 method clone
    =for code :lang<raku>
    method clone(@decls, *%opts) returns CSS::Properties
    =para Creates a deep copy of a CSS declarations object

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
                 Bool :$color-names = True,
                 Bool :$pretty = False,
                 Bool :$keep-defaults = False,
                 |c) is also<Str gist> {
        my CSS::Writer $writer .= new( :$color-names, :$pretty, |c);
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
            !! do with $.propertry-number(name) { self!lval(name, $_) } else { Nil }
    }
    method !value($_, \name, |c) is rw {
        .children
            ?? self!struct-value(name, .child-names)
            !! ( .box
                     ?? self!box-value(name, .edge-names)
                     !! self!item-value(name)
                    )
    }
    # build rw accessor for a named property
    method !lval(\name, $_ =  $.property-number(name)) is rw {
        self!value($!index[$_], name);
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
    multi method Bool(::?CLASS:D:) { %!values.Bool }
    multi method Bool(::?CLASS:U:) { Bool }
    method FALLBACK(Str \name, |c) is rw {
        with $.property-number(name) {
            self!lval(name, $_)
        }
        else {
            die X::Method::NotFound.new( :method(name), :typename(self.^name) )
        }
    }
}
