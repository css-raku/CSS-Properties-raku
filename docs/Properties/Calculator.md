class CSS::Properties::Calculator
---------------------------------

property calculator and measurement tool.

### method weigh

```raku
method weigh(
    $_,
    Int $delta = 0
) returns CSS::Properties::Calculator::FontWeight
```

converts a weight name to a three digit number: 100 lightest ... 900 heaviest

