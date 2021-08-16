use Test;
plan 6;
use CSS::Properties;
use CSS::Module::CSS3;

class AtFontFace is CSS::Properties {
      method new(:$module = CSS::Module::CSS3.module.sub-module<@font-face>,
                 |c) {
          nextwith(:$module, |c);
      }
}

my AtFontFace $font-face .= new: :style("font-family:'Sans-serif'; src:url('/myfonts/serif.otf'); font-stretch:condensed");

is $font-face.src, '/myfonts/serif.otf';


$font-face .= new: :style(q:to<END>);
    font-family: MyGentium;
    src: local(Gentium),    /* use locally available Gentium */
         url(Gentium.woff); /* otherwise, download it */
    END

is $font-face.src[0], 'Gentium'; 
is $font-face.src[0].type, 'local'; 
is $font-face.src[1], 'Gentium.woff';
is $font-face.src[1].type, 'url';
is $font-face.Str, "font-family:MyGentium; src:local(Gentium), url('Gentium.woff');";

