use CSS::Font;

#| A @font-face font descriptor rule
class CSS::Font::Descriptor is CSS::Font {
    use CSS::Module;
    use CSS::Module::CSS3;
    method new(:$module = CSS::Module::CSS3.module.sub-module<@font-face>, |c) {
        nextwith(:$module, |c);
    }
    method css handles<src> { callsame() }

    #| sets/gets the css font properties as a whole
    method font-props is rw {
        ...
    }

    multi method COERCE(Str:D $style) {
        self.new: :$style;
    }
}

=begin pod

=head2 Synopsis

=begin code :lang<raku>
use CSS::Font::Descriptor;
my CSS::Font::Descriptor $fd;
$fd .= new: style => q:to<END;
  font-family: "DejaVu Sans";
  src: url("fonts/DejaVuSans.ttf");
  font-variant: small-caps;
  END
# -- or --
$fd .= new: :font-family("DejaVu Sans"),
            :src<url("fonts/DejaVuSans.ttf")>,
            :font-variant<small-caps>;
=end code

=head3 Description

Objects of this class describe a single `@font-face` font descriptor rule.

This class is based on L<CSS::Font> and has all its methods available with the
exception of `font-props()`.

=end pod
