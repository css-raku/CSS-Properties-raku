use v6;

my enum Lengths is export(:Lengths) «
    :pt(1.0) :pc(12.0) :px(.75) :mm(2.8346) :cm(28.346) :in(72.0) :vw(0.0) :vh(0.0)
»;

my enum Resolutions is export(:Resolutions) « :dpi(1.0/in) :dpcm(1.0/cm) :dppx(1.0/px) »;

my enum Angles is export(:Angles) « :deg(1.0) :turn(360.0) :rad(57.2958) »;

my enum Time is export(:Time) « :s(1.0) :ms(0.001) »;

my enum Frequency is export(:Frequency) « :hz(1.0) :khz(1000.0) »;

my enum Percentages is export(:Percentages) ('%' => 100);

# Known functions: @font-face src: local() and :format()
my enum Function is export(:Function) « :local :format »;

#| utility definitions and operators for handing CSS Units
role CSS::Units[\dimension, \units] {

    =begin pod
    =head3 Synposis
    =begin code :lang<raku>
    use CSS::Units :ops, :pt, :px, :in, :mm;
    my $css = (require CSS::Properties).new: :margin[5pt, 10px, .1in, 2mm];
    =end code
    =head2 Description
    This module implements the following CSS Units
    =begin table
    Type | Units
    ---  | ----
    Length | pt pc px mm cm in em ex vw vh
    Resolution | dpi dpcm dpx
    Time | s ms
    Frequency | hz khz
    Percentage | %
    =end table
    =head3 Methods
    =end pod

    method dimension{dimension}
    method type{units}
    method units {units}
    method gist {self ~ units}

    multi method scale(Str $u) {
        self * (units eq $u ?? 1 !! dimension.enums{units} / dimension.enums{$u});
    }

    multi method scale(CSS::Units $v) {
        self.scale($v.type);
    }

    my subset Length of CSS::Units is export(:Length) where .dimension === Lengths;
    my subset Resolution of CSS::Units is export(:Resolution) where .dimension === Resolutions;

    sub postfix:<pt>(Numeric $v) is rw is export(:pt) { $v but CSS::Units[Lengths, 'pt']  };
    sub postfix:<pc>(Numeric $v) is rw is export(:pc) { $v but CSS::Units[Lengths, 'pc']  };
    sub postfix:<px>(Numeric $v) is rw is export(:px) { $v but CSS::Units[Lengths, 'px']  };
    sub postfix:<mm>(Numeric $v) is rw is export(:mm) { $v but CSS::Units[Lengths, 'mm']  };
    sub postfix:<cm>(Numeric $v) is rw is export(:cm) { $v but CSS::Units[Lengths, 'cm']  };
    sub postfix:<in>(Numeric $v) is rw is export(:in) { $v but CSS::Units[Lengths, 'in']  };
    sub postfix:<em>(Numeric $v) is rw is export(:em) { $v but CSS::Units[Lengths, 'em']  };
    sub postfix:<ex>(Numeric $v) is rw is export(:ex) { $v but CSS::Units[Lengths, 'ex']  };
    sub postfix:<vw>(Numeric $v) is rw is export(:vw) { $v but CSS::Units[Lengths, 'vw']  };
    sub postfix:<vh>(Numeric $v) is rw is export(:vh) { $v but CSS::Units[Lengths, 'vh']  };

    sub postfix:<dpi>(Numeric $v) is rw is export(:dpi) { $v but CSS::Units[Resolutions, 'dpi']  };
    sub postfix:<dpcm>(Numeric $v) is rw is export(:dpcm) { $v but CSS::Units[Resolutions, 'dpcm']  };
    sub postfix:<dppx>(Numeric $v) is rw is export(:dppx) { $v but CSS::Units[Resolutions, 'dppx']  };

    sub postfix:<turn>(Numeric $v) is rw is export(:turn) { $v but CSS::Units[Angles, 'turn']  };
    sub postfix:<deg>(Numeric $v) is rw is export(:deg) { $v but CSS::Units[Angles, 'deg']  };
    sub postfix:<rad>(Numeric $v) is rw is export(:rad) { $v but CSS::Units[Angles, 'rad']  };

    sub postfix:<s>(Numeric $v) is rw is export(:s) { $v but CSS::Units[Time, 's']  };
    sub postfix:<ms>(Numeric $v) is rw is export(:ms) { $v but CSS::Units[Time, 'ms']  };

    sub postfix:<hz>(Numeric $v) is rw is export(:hz) { $v but CSS::Units[Frequency, 'hz']  };
    sub postfix:<khz>(Numeric $v) is rw is export(:khz) { $v but CSS::Units[Frequency, 'khz']  };

    sub postfix:<%>(Numeric $v) is rw is export(:percent) { $v but CSS::Units[Percentages, 'percent']  };

    multi sub infix:<+>(CSS::Units $v, CSS::Units $n) is default is export(:ops) {
        ($v  +  $n.scale($v)) but CSS::Units[$v.dimension, $v.type];
    }
    multi sub infix:<+>(CSS::Units $v, 0) is default is export(:ops) {
        $v;
    }
    multi sub infix:<->(CSS::Units $v, CSS::Units $n) is default is export(:ops) {
        ($v  -  $n.scale($v)) but CSS::Units[$v.dimension, $v.type];
    }
    multi sub infix:<->(CSS::Units $v, 0) is default is export(:ops) {
        $v;
    }
    multi sub infix:«>css»(CSS::Units $v, CSS::Units $n) { $v > $n.scale($v) }
    multi sub infix:«<css»(CSS::Units $v, CSS::Units $n) { $v < $n.scale($v) }
    #| explicit add
    multi sub infix:<+css>(CSS::Units $v, CSS::Units $n) is export(:ops) { $v + $n }
    multi sub infix:<+css>(CSS::Units $v, 0) is export(:ops) { $v }
    #| explicit subtract
    multi sub infix:<-css>(CSS::Units $v, CSS::Units $n) is export(:ops) { $v - $n }
    multi sub infix:<-css>(CSS::Units $v, 0) is export(:ops) { $v }
}

role CSS::Units {
    use Color;

    sub dimension(\units) is export(:dimension) {
        (Lengths, Resolutions, Percentages, Angles, Time, Frequency, Function).first({.enums{units}:exists})
    }
    method value(\v, \units) {
        v ~~ Color|Hash|List
            ?? v does CSS::Units[dimension(units), units]
            !! v but  CSS::Units[dimension(units), units];
    }
}
