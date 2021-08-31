use Test;
plan 7;

use CSS::Font::Descriptor;

my CSS::Font::Descriptor $font-face .= new: :style("font-family:'Sans-serif'; src:url('/myfonts/serif.otf'); font-stretch:condensed");

is $font-face.src, '/myfonts/serif.otf';

$font-face .= new: :style(q:to<END>);
    font-family: MyGentium;
    src: local(Gentium),    /* use locally available Gentium */
         url(Gentium.woff); /* otherwise, download it */
    END

is $font-face.src[0].type, 'expr';
is $font-face.src[0][0], 'Gentium';

is $font-face.src[1].type, 'expr';
is $font-face.src[1][0], 'Gentium.woff';
is $font-face.src[1][0].type, 'url';

is $font-face.Str, "font-family:MyGentium; src:local(Gentium), url('Gentium.woff');";

