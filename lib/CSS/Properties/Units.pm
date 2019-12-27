use v6;

use CSS::Units :Resolutions, :Angles, :Time, :Frequency, :Percentages;
## This class is about to undergo deprecation - do not use in new code
## warn "CSS::Properties::Units is deprecated, Please use CSS::Units";
unit role CSS::Properties::Units does CSS::Units;

my enum Lengths is export(:Lengths) «
    :pt(1.0) :pc(12.0) :px(.75) :mm(2.8346) :cm(28.346) :in(72.0) :vw(0.0) :vh(0.0)
»;

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

