use v6;
use Test;
use CSS::Declarations;
use CSS::Writer;

my $writer = CSS::Writer.new: :terse;

my $css = CSS::Declarations.new( :style("color:red !important; background-repeat: repeat-x; border-left-style: inherit") );
my $ast = $css.ast;
is $ast, (:declaration-list[
                   {:expr[:keyw<repeat-x>], :ident<background-repeat>},
                   {:expr[:keyw<inherit>], :ident<border-left-style>},
                   {:expr[:rgb[:num(255), :num(0), :num(0)]], :ident<color>, :prio<important> }
               ]), 'ast';
is $writer.write( $ast ), 'background-repeat: repeat-x; border-left-style: inherit; color: rgb(255, 0, 0) !important;', 'style rebuilt';

$css = CSS::Declarations.new( :style("border-style: groove !important") );
is $writer.write( $css.ast ), "border-style: groove !important;", "round-trip of edge property";

$css = CSS::Declarations.new( :style("margin-top: 1pt; margin-left: 1pt; margin-bottom: 1pt; margin-right: 1pt;") );
is $writer.write($css.ast), "margin: 1pt;", "consolidation of edge properties";

$css = CSS::Declarations.new( :style("margin-bottom: 1pt; margin-left: 2pt; margin-right: 3pt; margin-top: 4pt;") );
is $writer.write($css.ast), "margin-bottom: 1pt; margin-left: 2pt; margin-right: 3pt; margin-top: 4pt;", "consolidation of edge properties";

todo "consolidation of compound properties";
$css = CSS::Declarations.new( :style("border-color: red; border-width: 2pt") );
is $writer.write($css.ast), "border: rgb(255, 0, 0) 2pt;", "consolidation of compound properties";

done-testing;
