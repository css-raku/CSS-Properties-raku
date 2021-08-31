use CSS::Font;

#| A @font-face rule
class CSS::Font::Descriptor is CSS::Font {
    use CSS::Module;
    use CSS::Module::CSS3;
    method new(:$module = CSS::Module::CSS3.module.sub-module<@font-face>, |c) {
        nextwith(:$module, |c);
    }
    method css handles<src font-family> { callsame() }
    #| sets/gets the css font properties as a whole
    method font-props is rw {
        Proxy.new(
            FETCH => sub ($) { $.css },
            STORE => sub ($, Str :$style) {
                $.css .= clone: $style;
                self.setup;
            });
    }

}
