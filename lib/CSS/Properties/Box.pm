use v6;

use CSS::Box;

warn "CSS::Properties::Box is deprecated. Please use CSS::Box";

unit class CSS::Properties::Box is CSS::Box;

my Int enum Edges is export(:Edges) <Top Right Bottom Left>;
