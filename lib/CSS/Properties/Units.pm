use v6;

#| utility definitions and operators for handing CSS Units

my enum Lengths is export(:Lengths) «
    :pt(1.0) :pc(12.0) :px(.75) :mm(2.8346) :cm(28.346) :in(72.0) :vw(0.0) :vh(0.0)
»;
my enum Resolutions «
   :dpi(72.0) :dpcm(28.346)
»;

my enum Colors is export(:Colors) «
   :rgb :rgba :hsl :hsla
»;

my enum Percentages ('%' => 100);

role CSS::Properties::Units[\dimension, \units] {

    my constant Units = CSS::Properties::Units;
    method dimension{dimension}
    method type{units}
    method gist {self~ units}

    multi method scale(Str $u) {
        self * (units eq $u ?? 1 !! dimension.enums{units} / dimension.enums{$u});
    }

    multi method scale(Units $v) {
        self.scale($v.type);
    }

    my subset Length of Units is export(:Length) where .dimension === Lengths;
    my subset Resolution of Units is export(:Resolution) where .dimension === Resolutions;

    sub postfix:<pt>(Numeric $v) is rw is export(:pt) { $v but Units[Lengths, 'pt']  };
    sub postfix:<pc>(Numeric $v) is rw is export(:pc) { $v but Units[Lengths, 'pc']  };
    sub postfix:<px>(Numeric $v) is rw is export(:px) { $v but Units[Lengths, 'px']  };
    sub postfix:<mm>(Numeric $v) is rw is export(:mm) { $v but Units[Lengths, 'mm']  };
    sub postfix:<cm>(Numeric $v) is rw is export(:cm) { $v but Units[Lengths, 'cm']  };
    sub postfix:<in>(Numeric $v) is rw is export(:in) { $v but Units[Lengths, 'in']  };
    sub postfix:<em>(Numeric $v) is rw is export(:em) { $v but Units[Lengths, 'em']  };
    sub postfix:<ex>(Numeric $v) is rw is export(:ex) { $v but Units[Lengths, 'ex']  };
    sub postfix:<vw>(Numeric $v) is rw is export(:vw) { $v but Units[Lengths, 'vw']  };
    sub postfix:<vh>(Numeric $v) is rw is export(:vh) { $v but Units[Lengths, 'vh']  };

    sub postfix:<dpi>(Numeric $v) is rw is export(:dpi) { $v but Units[Resolutions, 'dpi']  };
    sub postfix:<dpcm>(Numeric $v) is rw is export(:dpcm) { $v but Units[Resolutions, 'dpcm']  };

    sub postfix:<%>(Numeric $v) is rw is export(:percent) { $v but Units[Percentages, 'percent']  };

    multi sub infix:<+>(Units $v, Units $n) is default is export(:ops) {
        ($v  +  $n.scale($v)) but Units[$v.dimension, $v.type];
    }
    multi sub infix:<+>(Units $v, 0) is default is export(:ops) {
        $v;
    }
    multi sub infix:<->(Units $v, Units $n) is default is export(:ops) {
        ($v  -  $n.scale($v)) but Units[$v.dimension, $v.type];
    }
    multi sub infix:<->(Units $v, 0) is default is export(:ops) {
        $v;
    }
    multi sub infix:«>css»(Units $v, Units $n) { $v > $n.scale($v) }
    multi sub infix:«<css»(Units $v, Units $n) { $v < $n.scale($v) }
    #| explicit add
    multi sub infix:<+css>(Units $v, Units $n) is export(:ops) { $v + $n }
    multi sub infix:<+css>(Units $v, 0) is export(:ops) { $v }
    #| explicit subtract
    multi sub infix:<-css>(Units $v, Units $n) is export(:ops) { $v - $n }
    multi sub infix:<-css>(Units $v, 0) is export(:ops) { $v }
}

role CSS::Properties::Units {
    use Color;

    sub dimension(\units) is export(:dimension) {
        (Lengths, Resolutions, Colors, Percentages).first({.enums{units}:exists})
    }
    method value(\v, \units) {
        v ~~ Color|Hash|List
            ?? v does CSS::Properties::Units[dimension(units), units]
            !! v but  CSS::Properties::Units[dimension(units), units];
    }
}
