defmodule MiLexerTest do
  alias Mi.Lexer
  alias Mi.Token
  use   ExUnit.Case

  describe "&Lexer.lex/1" do
    test "Keywords are recognized" do
      {:ok, tokens} = Lexer.lex("""
      lambda define use loop cond case try catch throw true false nil
      """)
      assert [%Token{type: :lambda, value: "lambda"},
              %Token{type: :define, value: "define"},
              %Token{type: :use, value: "use"},
              %Token{type: :loop, value: "loop"},
              %Token{type: :cond, value: "cond"},
              %Token{type: :case, value: "case"},
              %Token{type: :try, value: "try"},
              %Token{type: :catch, value: "catch"},
              %Token{type: :throw, value: "throw"},
              %Token{type: :true, value: "true"},
              %Token{type: :false, value: "false"},
              %Token{type: :nil, value: "nil"}] = tokens
    end

    test "Keywords aren't recognized when part of a longer identifier" do
      {:ok, tokens} = Lexer.lex("""
      lambda- definee used loopp cond- case- tryy catchh throww
      truee falsey nill
      """)
      Enum.map(tokens, fn(token) -> assert token.type === :identifier end)
    end

    test "String literals are recognized and read properly" do
      {:ok, tokens} = Lexer.lex(~s("I'm Å \\"string\\"" "I'm a seperate string!"))

      assert [%Token{type: :string, value: ~s(I'm Å \\"string\\")},
              %Token{type: :string, value: ~s(I'm a seperate string!)}] = tokens
    end

    # TODO: parse negative numbers (make unary minus operator or lex it as a
    #       whole?), scientific numbers (2e9) and other bases (# or 0x?)
    test "Number literals are recognized and read properly" do
      {:ok, tokens} = Lexer.lex("0.45 2.3 5.3 1000000 86 0 1 00000")

      assert [%Token{type: :number, value: "0.45"},
              %Token{type: :number, value: "2.3"},
              %Token{type: :number, value: "5.3"},
              %Token{type: :number, value: "1000000"},
              %Token{type: :number, value: "86"},
              %Token{type: :number, value: "0"},
              %Token{type: :number, value: "1"},
              %Token{type: :number, value: "00000"}] = tokens
    end

    test "Unterminated strings error" do
      {:error, reason} = Lexer.lex(~s("I'm an unterminated \\"string\\" over
      multiple lines))

      assert reason === "1:1: unterminated string"
    end

    test "Identifier literals are recognized and read properly" do
      {:ok, tokens} = Lexer.lex("""
      console/log document/write an-identifier20 b2-2 simpleident x y z
      """)

      Enum.map(tokens, fn(token) -> assert token.type === :identifier end)
    end

    test "Operators are recoginized properly" do
      {:ok, tokens} = Lexer.lex("""
      +  ++  -  --  /  //  *  %  **  <  > <=  >=  <<  >>  >>>  ~  ^ & not .
      and  or  eq  delete  typeof  void  new instanceof  in
      """)

      assert [%Token{type: :add, value: "+"},
              %Token{type: :increment, value: "++"},
              %Token{type: :subtract, value: "-"},
              %Token{type: :decrease, value: "--"},
              %Token{type: :divide, value: "/"},
              %Token{type: :intdivide, value: "//"},
              %Token{type: :*, value: "*"},
              %Token{type: :modulo, value: "%"},
              %Token{type: :power, value: "**"},
              %Token{type: :lt, value: "<"},
              %Token{type: :gt, value: ">"},
              %Token{type: :lteq, value: "<="},
              %Token{type: :gteq, value: ">="},
              %Token{type: :bshiftl, value: "<<"},
              %Token{type: :bshiftr, value: ">>"},
              %Token{type: :ubshiftr, value: ">>>"},
              %Token{type: :bnot, value: "~"},
              %Token{type: :bxor, value: "^"},
              %Token{type: :band, value: "&"},
              %Token{type: :not, value: "not"},
              %Token{type: :dot, value: "."},
              %Token{type: :and, value: "and"},
              %Token{type: :or, value: "or"},
              %Token{type: :eq, value: "eq"},
              %Token{type: :delete, value: "delete"},
              %Token{type: :typeof, value: "typeof"},
              %Token{type: :void, value: "void"},
              %Token{type: :new, value: "new"},
              %Token{type: :instanceof, value: "instanceof"},
              %Token{type: :in, value: "in"}] = tokens
    end

    test "Comments are skipped" do
      {:ok, tokens_a} = Lexer.lex("""
      (define x 10) ; Insightful comment
      (* x/n x/m)
      """)
      assert [%Token{type: :oparen},
              %Token{type: :define},
              %Token{type: :identifier},
              %Token{type: :number},
              %Token{type: :cparen},
              %Token{type: :oparen},
              %Token{type: :*},
              %Token{type: :identifier},
              %Token{type: :identifier},
              %Token{type: :cparen}] = tokens_a

      {:ok, tokens_b} = Lexer.lex("; Some other important comment")
      assert tokens_b === []
    end

    test "Line and character numbers are tracked" do
      {:ok, tokens} = Lexer.lex("""
      ((define z '(1 2 3))
       (define add (lambda (a b) (+ a b)))
      """)

      [%Token{line: 1, pos: 1}, %Token{line: 1, pos: 2},
       %Token{line: 1, pos: 3}, %Token{line: 1, pos: 10},
       %Token{line: 1, pos: 12}, %Token{line: 1, pos: 13},
       %Token{line: 1, pos: 14}, %Token{line: 1, pos: 16},
       %Token{line: 1, pos: 18}, %Token{line: 1, pos: 19},
       %Token{line: 1, pos: 20}, %Token{line: 2, pos: 2},
       %Token{line: 2, pos: 3}, %Token{line: 2, pos: 10},
       %Token{line: 2, pos: 14}, %Token{line: 2, pos: 15},
       %Token{line: 2, pos: 22}, %Token{line: 2, pos: 23},
       %Token{line: 2, pos: 25}, %Token{line: 2, pos: 26},
       %Token{line: 2, pos: 28}, %Token{line: 2, pos: 29},
       %Token{line: 2, pos: 31}, %Token{line: 2, pos: 33},
       %Token{line: 2, pos: 34}, %Token{line: 2, pos: 35},
       %Token{line: 2, pos: 36}] = tokens
    end
  end
end
