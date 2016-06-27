use v6;

class CSS::Declarations::Delegator {

    use CSS::Declarations :Units;

    multi method from-ast(List $v) {
        $v.elems == 1
            ?? self.from-ast( $v[0] )
            !! [ $v.map: {self.from-ast($_) } ];
    }
    #| { :int(42) } => :int(42)
    multi method from-ast(Hash $v where .keys == 1) {
        self.from-ast($v.pairs[0]);
    }
    multi method from-ast(Pair $v) {
        my $val = do given $v.key {
            when 'pt'|'pc'|'px'|'mm'|'cm' {
                $v.value * Units.enums<px> / Units.enums{$_};
            }
            default {
                self.from-ast($v.value);
            }
        } does role { has Str $.key is rw };
        $val.key = $v.key;
        $val;
    }
    multi method from-ast($v) is default {
        $v
    }

    method coerce($v) {
        self.from-ast($v);
    }

}
