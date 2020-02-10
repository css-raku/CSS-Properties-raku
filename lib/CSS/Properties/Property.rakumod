use v6;

use CSS::Module;
use CSS::Module::Property;

class CSS::Properties::Property {

    has CSS::Module::Property $!meta handles<name prop-num inherit initial important synopsis default default-type edge edges edge-names children child-names>;
    method box { False }

    multi method build(UInt:D :$prop-num!, CSS::Module :$module!) {
        $!meta = $module.index[ $prop-num ];
        die "{$!meta.name} css property should be composed via CSS::Properties::Edges"
            if $!meta.box && !self.box;
    }
    multi method build(Str:D :$name!, CSS::Module :$module = (require CSS::Module::CSS3).module) {
        my $prop-num := $module.property-number($name)
            // die "unknown css property: $name";
        self.build(:$prop-num, :$module);
    }
    method TWEAK(|c) {
        self.build(|c);
    }

    method default-value {
        # kludgy default handling
        my $val := $.default;
        with $.default-type {
            when "keyw" {
                [ $val eq 'transparent' ?? :rgba[ :num(0) xx 4] !! ($_ => $val) ];
            }
            when "num"|"px"      { [$_ => $val.Int] } 
            when $val eq '0% 0%' { [:percent(0) xx 2] }
            default { warn "ignoring default value: $_:$val" }
        }
        else {
            Nil
        }
    }

}
