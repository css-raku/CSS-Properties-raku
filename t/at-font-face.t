use Test;
plan 20;

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

$font-face .= new: :style(q:to<END>);
    font-family: MyFont;
    src: local(MyFont),
         url(MyFont.woff) format('woff'),
         url(MyFont.otf) format('opentype');
    END

is $font-face.src[0].type, 'expr';
is $font-face.src[0][0], 'MyFont';

is $font-face.src[1].type, 'expr';
is $font-face.src[1][0], 'MyFont.woff';
is $font-face.src[1][0].type, 'url';
is $font-face.src[1][1], 'woff';
is $font-face.src[1][1].type, 'format';

is $font-face.src[2].type, 'expr';
is $font-face.src[2][0], 'MyFont.otf';
is $font-face.src[2][0].type, 'url';
is $font-face.src[2][1], 'opentype';
is $font-face.src[2][1].type, 'format';

is $font-face.Str, "font-family:MyFont; src:local(MyFont), url('MyFont.woff') format('woff'), url('MyFont.otf') format('opentype');";

