# Mi!

`stable`|`development`
--------|-----------------------
[![Build Status](https://travis-ci.com/muse/mi.svg?token=uTxXTcaEfuzWqF3Yjwi2&branch=master)](https://travis-ci.com/muse/mi)|[![Build Status](https://travis-ci.com/muse/mi.svg?token=uTxXTcaEfuzWqF3Yjwi2&branch=develop)](https://travis-ci.com/muse/mi)

### What's Mi?
Mi is a Javascript transpiler using its own lisp dialect.

### Installing Mi
Mi is build in Elixir and requires `elixir` and `mix` to be installed. We'll be
using mix to build a binary.

```
$ git clone https://github.com/muse/mi
$ cd mi
$ mix escript.build
$ chmod +x mi
```

You now have a Mi binary locally available under `./mi`. Mi as of right now
reads from stdin and isn't production ready at all, this means it will emit AST
nodes until then.

### Using Mi
```
/tmp/mi ─── ./mi <<< "(define x 5)"
[%Mi.Token{line: 1, pos: 1, type: :oparen, value: "("},
 %Mi.Token{line: 1, pos: 2, type: :define, value: "define"},
 %Mi.Token{line: 1, pos: 9, type: :identifier, value: "x"},
 %Mi.Token{line: 1, pos: 11, type: :number, value: "5"},
 %Mi.Token{line: 1, pos: 12, type: :cparen, value: ")"}]
'# ======= #'
[%Mi.AST.Variable{default?: false, name: "x",
  value: %Mi.AST.Number{value: "5"}}]
```
