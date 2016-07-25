use v6;

module CSS::Declarations::Units {
    my enum Units is export « :pt(1.0) :pc(12.0) :px(.75) :mm(28.346) :cm(2.8346) :in(1/72) »;
    role Keyed[$key] { method key{$key} }
    subset Length of Keyed is export where .key eq 'pt'|'pc'|'px'|'mm'|'cm'|'in';
    sub postfix:<pt>(Numeric $v) is rw is export { $v does Keyed['pt']  };
    sub postfix:<pc>(Numeric $v) is rw is export { $v does Keyed['pc']  };
    sub postfix:<px>(Numeric $v) is rw is export { $v does Keyed['px']  };
    sub postfix:<mm>(Numeric $v) is rw is export { $v does Keyed['mm']  };
    sub postfix:<cm>(Numeric $v) is rw is export { $v does Keyed['cm']  };
    sub postfix:<in>(Numeric $v) is rw is export { $v does Keyed['in']  };
    multi sub infix:<+>(Length $v, Length $n) is export {
        my $r = $v.key eq $n.key ?? 1 !! Units.enums{$v.key} / Units.enums{$n.key};
        ($v.Numeric  +  $r * $n.Numeric) does Keyed[$v.key];
    }
    multi sub infix:<->(Length $v, Length $n) is export {
        my $r = $v.key eq $n.key ?? 1 !! Units.enums{$v.key} / Units.enums{$n.key};
        ($v.Numeric  -  $r * $n.Numeric) does Keyed[$v.key];
    }
}
