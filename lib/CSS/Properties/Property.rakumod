use v6;

use CSS::Module;
use CSS::Module::Property;

#| Meta-data for a given property
class CSS::Properties::Property {

    =begin pod

    =head2 Synopsis
    =begin code :lang<raku>
    use CSS::Properties::Property;
    my CSS::Properties::Property %edges = <top right bottom left>.map: {
        $_ => CSS::Properties::Property.new: :name('margin-' ~ $_);
    }
    my CSS::Properties::Property $margin-info .= new: :name<margin>, :%edges;
    is-deeply $margin-info.name, 'margin', '$prop.name';
    say $margin-info.box;      # True
    say $margin-info.inherit;  # False
    say $margin-info.synopsis; # <margin-width>{1,4}
    say $margin-info.top.name, # margin-top
    =end code

    =head2 Description

    Information class for individual properties

    =head2 Methods

    =head3 new
    =begin code :lang<raku>
     method new(
        Str :$prop-name,   # property name e.g. 'margin-top'
        CSS::Module :$module = CSS::Module::CSS3.new(), 
        CSS::Properties::Property :%edges{ :$top, :$left, :$bottom, :$right},
     ) returns CSS::Properties::Property;
    =end code
    =para Returns a new object containing inforation on the given property

    =head 2 Accessors
    The following L<CSS::Module::Property> accessors are handled by this object
    =begin table
    Name | Type | Description
    -----+------+------------
    name        | Str  | Property name, e.g. 'top-margin'
    prop-num    | UInt | A unique number for the property
    inherit     | Bool | The property is inherited?
    initial     | Bool | Property should reset to it's initial value?
    important   | Bool | Property has !important inheritance mode
    synposis    | Bool | Property value L<syntax|http://www.w3.org/TR/CSS21/about.html#property-defs> definition
    default-value | Any | Default value for the property
    edge-names  | List | top, right, bottom, left components [1]
    child-names | List | child components [2]
    =end table

    Notes:
    =item [1] for example `margin` has edge-names `top-margin` ... `left-margin`
    =item [2] for example `font` has child-names `family-name`, `font-weight` ...
    =end pod

    my class Edges {
        has CSS::Properties::Property $.top is required;
        has CSS::Properties::Property $.left is required;
        has CSS::Properties::Property $.bottom is required;
        has CSS::Properties::Property $.right is required;
    }
    has Edges $!edges handles<top left bottom right>;
    has CSS::Module::Property $!meta handles<name prop-num inherit initial important synopsis default default-type edge edges edge-names children child-names>;
    method box { $!meta.edges.so }

    multi method build(UInt:D :$prop-num!, CSS::Module :$module!, :%edges) {
        $!meta = $module.index[ $prop-num ];
        if $!meta.edges {
            die "missing required :%edges on property {$!meta.name}"
                if %edges{"top"|"left"|"bottom"|"right"} ~~ Any:U;
            $!edges .= new: |%edges;
        }
        else {
            warn "ignoring :%edges on property {$!meta.name}"
                if %edges;
        }
    }
    multi method build(Str:D :$name!, CSS::Module :$module = (require CSS::Module::CSS3).module, |c) {
        my $prop-num := $module.property-number($name)
            // die "unknown css property: $name";
        self.build(:$prop-num, :$module, |c);
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
