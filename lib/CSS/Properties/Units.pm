use v6;

#| utility definitions and operators for handing CSS Units

unit role CSS::Properties::Units[$units];

my enum Scale is export(:Scale) «
   :pt(1.0) :pc(12.0) :px(.75) :mm(2.8346) :cm(28.346) :in(72.0) :vw(0.0) :vh(0.0)
   :dpi(72.0), :dpcm(28.346)
»;

my constant Units = CSS::Properties::Units;
method type{$units}
method gist {self~ $units}
multi method scale(Str $u) {
    self * ($units eq $u ?? 1 !! Scale.enums{$units} / Scale.enums{$u});
}
multi method scale(Units $v) {
    self.scale($v.type);
}
my subset LengthUnits of Str where 'pt'|'pc'|'px'|'mm'|'cm'|'in';
my subset ResolutionUnits of Str where 'dpi'|'dpm';
my subset Length of Units is export(:Length) where .type ~~ LengthUnits;
my subset Resolution of Units is export(:Resolution) where .type ~~ ResolutionUnits;
sub postfix:<pt>(Numeric $v) is rw is export(:pt) { $v but Units['pt']  };
sub postfix:<pc>(Numeric $v) is rw is export(:pc) { $v but Units['pc']  };
sub postfix:<px>(Numeric $v) is rw is export(:px) { $v but Units['px']  };
sub postfix:<mm>(Numeric $v) is rw is export(:mm) { $v but Units['mm']  };
sub postfix:<cm>(Numeric $v) is rw is export(:cm) { $v but Units['cm']  };
sub postfix:<in>(Numeric $v) is rw is export(:in) { $v but Units['in']  };
sub postfix:<em>(Numeric $v) is rw is export(:em) { $v but Units['em']  };
sub postfix:<ex>(Numeric $v) is rw is export(:ex) { $v but Units['ex']  };
sub postfix:<vw>(Numeric $v) is rw is export(:vw) { $v but Units['vw']  };
sub postfix:<vh>(Numeric $v) is rw is export(:vh) { $v but Units['vh']  };
sub postfix:<dpi>(Numeric $v) is rw is export(:dpi) { $v but Units['dpi']  };
sub postfix:<dpcm>(Numeric $v) is rw is export(:dpcm) { $v but Units['dpcm']  };
sub postfix:<%>(Numeric $v) is rw is export(:percent) { $v but Units['percent']  };

multi sub infix:<+>(Units $v, Units $n) is default is export(:ops) {
    ($v  +  $n.scale($v)) but Units[$v.type];
}
multi sub infix:<+>(Units $v, 0) is default is export(:ops) {
    $v;
}
multi sub infix:<->(Units $v, Units $n) is default is export(:ops) {
    ($v  -  $n.scale($v)) but Units[$v.type];
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
