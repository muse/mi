# Grammar specification
This document containts Mi's grammar as it is used to parse source files.

```
list ::= "(", { sexpr }, ")" ;
sexpr ::= atom | list | ;
quote ::= "'", sexpr ;

digit ::= "0" | ... | "9" ;
letter ::= ("a" | ... | "z") | ("A" | ... | "Z") ;

identifier ::= letter, { letter | digit | "/" | "#" | "-" } ;
string ::= '"', { ? all characters ? - '"' | '\"' }, '"' ;
symbol ::= ":", { letter | "_" | "-" | "+" | "*" | "/" | "%" | "^" | "@" | "!"
                  | "&" | "|" } ;
number ::= [ "-" ], ({ digit } | { digit }, ".", { digit }) ;
scientific-number ::= { number }, "e", [ "-" ], { digit } ;

atom ::= identifier
       | number
       | string
       | symbol
       | quote
       | use-expr
       | define-expr;

arg-list ::= "(", { identifier } | , ")" ; => (defun test (a b c)

use-expr ::= "use", [ "*" ], list | string ;
define-expr ::= "define", [ "*" ], identifier, sexpr ;
lambda-expr ::= "lambda", arg-list, sexpr ;
```
