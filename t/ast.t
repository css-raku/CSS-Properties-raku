use v6;
use Test;
use CSS::Declarations;

my $css = CSS::Declarations.new( :style("color:red !important; background-repeat: repeat-x; border-left-style: inherit") );
is $css.ast(:!optimize), (:declaration-list[
                   {:expr[:keyw<repeat-x>], :ident<background-repeat>},
                   {:expr[:keyw<inherit>], :ident<border-left-style>},
                   {:expr[:rgb[:num(255), :num(0), :num(0)]], :ident<color>, :prio<important> }
               ]), 'ast';
is $css.write(:!optimize), 'background-repeat: repeat-x; border-left-style: inherit; color: red !important;', 'style unoptimized';

my $ast = $css.ast;
is $ast, (:declaration-list[
                   {:expr["expr:background-repeat" => [:keyw("repeat-x")]], :ident("background")},
                   {:expr[:keyw<inherit>], :ident<border-left-style>},
                   {:expr[:rgb[:num(255), :num(0), :num(0)]], :ident<color>, :prio<important> }
               ]), 'ast';
is $css.write , 'background: repeat-x; border-left-style: inherit; color: red !important;', 'style optimized';

done-testing;
