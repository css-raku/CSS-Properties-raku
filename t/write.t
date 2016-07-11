use v6;
use Test;
use CSS::Declarations;

my $css = CSS::Declarations.new( :style("border-style: groove !important") );
is $css.write(:!optimize), "border-bottom-style: groove !important; border-left-style: groove !important; border-right-style: groove !important; border-top-style: groove !important;", "unoptimized edge property";
is $css.write, "border: groove !important;", "edge property";

$css = CSS::Declarations.new( :style("margin-top: 1pt; margin-left: 1pt; margin-bottom: 1pt; margin-right: 1pt;") );
is $css.write, "margin: 1pt;", "consolidation of edge properties";

$css = CSS::Declarations.new( :style("margin-bottom: 1pt; margin-left: 2pt; margin-right: 3pt; margin-top: 4pt;") );
is $css.write, "margin-bottom: 1pt; margin-left: 2pt; margin-right: 3pt; margin-top: 4pt;", "consolidation of edge properties";

$css = CSS::Declarations.new( :style("border-color: rgb(255,0,0); border-width: 2pt") );
is $css.write, "border: red 2pt;", "optimized properties";

$css = CSS::Declarations.new( :style("margin: inherit") );
is $css.write(:!optimize), "margin-bottom: inherit; margin-left: inherit; margin-right: inherit; margin-top: inherit;", "edge unoptimized";
is $css.write, "margin: inherit;", "edge optimized";

done-testing;
