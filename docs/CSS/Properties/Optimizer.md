[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Properties Module]](https://css-raku.github.io/CSS-Properties-raku)
 / [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties)
 :: [Optimizer](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties/Optimizer)

class CSS::Properties::Optimizer
--------------------------------

Optimizer for CSS Property ASTs

Description
-----------

This class is used to perform optimization on an intermediate property list AST, prior to serialization to reduce the overall size and number of properties.

This involves combining component properties into container properties (`border-style`, `border-width`, ... => `border`), or combining edges (`margin-top`, `margin-left`, ... => `margin`). Properties that have been set to the default value are also removed.

### Example

The optimizer is commonly used internally by CSS::Properties to optimize properties, but it can alsp be used stand-alone to optimize AST trees from parsed property lists, as in this example.

The easiest way of creating an object is to create a [CSS::Properties](https://css-raku.github.io/CSS-Properties-raku/CSS/Properties) object, then dereference the optimizer:

```raku
use CSS::Properties;
use CSS::Properties::Optimizer;
use CSS::Module::CSS3;
use CSS::Writer;

my $module = CSS::Module::CSS3.module;
my CSS::Properties $css .= new: :$module;
my CSS::Properties::Optimizer $optimizer = $css.optimizer;
my $actions = $module.actions.new;
my CSS::Writer $writer .= new: :color-names, :!pretty;
my $declarations = "border-bottom-color:red; border-bottom-style:solid; border-bottom-width:1px; border-left-color:red; border-left-style:solid; border-left-width:1px; border-right-color:red; border-right-style:solid; border-right-width:1px; border-top-color:red; border-top-style:solid; border-top-width:1px;";
my $p = $module.grammar.parse($declarations, :$actions, :rule<declaration-list>);
my %ast = $optimizer.optimize($p.ast);
say $writer.write(|%ast); # border:1px solid red;
```

