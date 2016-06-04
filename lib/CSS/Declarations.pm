use v6;

use CSS::Declarations::Property;
use CSS::Declarations::Box;

class CSS::Declarations {

    my enum Units « :pt(1.0) :pc(12.0) :px(.75) :mm(28.346) :cm(2.8346) »;

    #| contextual variables
    has Numeric $.em = 16 * px;     #| font-size scaling factor, e.g.: 2em
    has Numeric $.ex = 12 * px;     #| font x-height scaling factor, e.g.: ex
    has Units $.length-units = px;  #| target units

    our %properties;   #| property definitions
    has Any %!values;  #| property values

    BEGIN my %metadata = %CSS::Declarations::Property::Metadata;

    multi sub make-property( Str $name where { %properties{$name}:exists })  {
        %properties{$name}
    }

    multi sub make-property(Str $name) {
        if $name ~~ /^'@'/ {
            warn "todo: $name";
            return;
        }
        die "unknown property: $name"
            unless %metadata{$name}:exists;
        my %defs = %metadata{$name};
        my $class = CSS::Declarations::Property;
        if %metadata{$name}<children>:exists {
            # e.g. margin, comprised of margin-top, margin-rgit, margin-bottom, margin-left
            $class = CSS::Declarations::Box;
            for %metadata{$name}<children>.list -> $side {
                # these shouldn't nest or cycle
                die "err, what are we building here? $side"
                    if %metadata{$side}<children>:exists
                    || $side eq $name;                         
                %defs{$side} = make-property($side);
            }
        }
        %properties{$name} = $class.new( :$name, |%defs );
    }

    BEGIN {
        warn "making properties...";
        make-property($_)
            for %metadata.keys.sort;
    }

    submethod BUILD( :$!em, :$!ex ) {
        # setup base property defaults
    }
}
