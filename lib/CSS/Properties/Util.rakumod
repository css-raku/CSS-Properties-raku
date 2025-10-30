unit module CSS::Properties::Util;

use CSS::Units :Function;
use Color;
use Color::Conversion;

my subset ColorAST of Pair where {.key ~~ 'rgb'|'rgba'|'hsl'|'hsla'}
my subset Keyword  of Pair where {.key ~~ 'keyw'}
my enum Colors « :rgb :rgba :hsl :hsla »;
my subset KnownFunction of Str:D where 'local'|'format';
my constant TransparentColor = (Color but CSS::Units[Colors, 'rgba']).new( :r(0), :g(0), :b(0), :a(0));

my Lock:D $lock .= new;

proto sub from-ast($) is export(:from-ast) {*}
multi sub from-ast(ColorAST $v) {
    my @channels = $v.value.map: {from-ast($_)};
    my Color $color;
    my $type = $v.key;
    if $type ~~ 'rgba'|'hsla' {
        @channels.tail *= (@channels.tail.type ~~ 'percent'
                           ?? 2.56 !! 256);
    }

    $color .= new: |($type => @channels);

    $color does CSS::Units[Colors, $type];
}
multi sub from-ast(Keyword $v) {
    $lock.protect: {
        state $cache //= %(
            'transparent' => TransparentColor,
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
            $ast.push: $v.a.&alpha
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

#| convert 0 .. 255  =>  0.0 .. 1.0. round to 2 decimal places
sub alpha($a) {
    :num(($a * 100/256).round / 100);
}

