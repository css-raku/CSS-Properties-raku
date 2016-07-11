use v6;
use Test;
use CSS::Declarations;
use CSS::Writer;

my $writer = CSS::Writer.new: :terse;

my $css = CSS::Declarations.new( :style("color:red !important; background-repeat: repeat-x; border-left-style: inherit") );
my $ast = $css.ast(:!optimize);
is $ast, (:declaration-list[
                   {:expr[:keyw<repeat-x>], :ident<background-repeat>},
                   {:expr[:keyw<inherit>], :ident<border-left-style>},
                   {:expr[:rgb[:num(255), :num(0), :num(0)]], :ident<color>, :prio<important> }
               ]), 'ast';
is $writer.write( $ast ), 'background-repeat: repeat-x; border-left-style: inherit; color: rgb(255, 0, 0) !important;', 'style unoptimized';

$ast = $css.ast;
is $ast, (:declaration-list[
                   {:expr["expr:background-repeat" => [:keyw("repeat-x")]], :ident("background")},
                   {:expr[:keyw<inherit>], :ident<border-left-style>},
                   {:expr[:rgb[:num(255), :num(0), :num(0)]], :ident<color>, :prio<important> }
               ]), 'ast';
is $writer.write( $ast ), 'background: repeat-x; border-left-style: inherit; color: rgb(255, 0, 0) !important;', 'style optimized';

done-testing;
