defmodule MiParserTest do
  alias Mi.{Token, Parser, AST}
  use   ExUnit.Case

  describe "&Parser.parse/1" do
    test "Literal lists are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :quote, value: "'"},
         %Token{line: 1, pos: 3, type: :oparen, value: "("},
         %Token{line: 1, pos: 4, type: :number, value: "1"},
         %Token{line: 1, pos: 6, type: :string, value: "ok"},
         %Token{line: 1, pos: 9, type: :number, value: "3"},
         %Token{line: 1, pos: 11, type: :number, value: "4"},
         %Token{line: 1, pos: 12, type: :cparen, value: ")"},
         %Token{line: 1, pos: 14, type: :quote, value: "'"},
         %Token{line: 1, pos: 15, type: :oparen, value: "("},
         %Token{line: 1, pos: 16, type: :cparen, value: ")"},
         %Token{line: 1, pos: 18, type: :quote, value: "'"},
         %Token{line: 1, pos: 19, type: :oparen, value: "("},
         %Token{line: 1, pos: 20, type: :quote, value: "'"},
         %Token{line: 1, pos: 21, type: :oparen, value: "("},
         %Token{line: 1, pos: 22, type: :cparen, value: ")"},
         %Token{line: 1, pos: 23, type: :cparen, value: ")"},
         %Token{line: 1, pos: 24, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [[
        %AST.List{items: [%AST.Number{value: "1"},
                          %AST.String{value: "ok"},
                          %AST.Number{value: "3"},
                          %AST.Number{value: "4"}]},
        %AST.List{items: []},
        %AST.List{items: [%AST.List{items: []}]}
      ]] === ast
    end

    test "Expressions are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :+, value: "+"},
         %Token{line: 1, pos: 4, type: :number, value: "1"},
         %Token{line: 1, pos: 6, type: :number, value: "2"},
         %Token{line: 1, pos: 8, type: :oparen, value: "("},
         %Token{line: 1, pos: 9, type: :*, value: "*"},
         %Token{line: 1, pos: 11, type: :number, value: "3"},
         %Token{line: 1, pos: 13, type: :number, value: "3"},
         %Token{line: 1, pos: 14, type: :cparen, value: ")"},
         %Token{line: 1, pos: 15, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Expression{
          operator: :+,
          arguments: [%AST.Number{value: "1"},
                      %AST.Number{value: "2"},
                      %AST.Expression{
                        operator: :*,
                        arguments: [
                          %AST.Number{value: "3"},
                          %AST.Number{value: "3"}
                        ]
                      }]}
      ] === ast
    end

    test "Expressions error accordingly" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :*, value: "*"},
         %Token{line: 1, pos: 4, type: :number, value: "1"},
         %Token{line: 1, pos: 5, type: :cparen, value: ")"}]

      {:error, error} = Parser.parse(tokens)
      assert String.contains?(error, "not enough arguments")

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :typeof, value: "typeof"},
         %Token{line: 1, pos: 9, type: true, value: "true"},
         %Token{line: 1, pos: 14, type: false, value: "false"},
         %Token{line: 1, pos: 19, type: :cparen, value: ")"}]

      {:error, error} = Parser.parse(tokens)
      assert String.contains?(error, "too many arguments")

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :-, value: "-"},
         %Token{line: 1, pos: 3, type: :cparen, value: ")"}]

      {:error, error} = Parser.parse(tokens)
      assert String.contains?(error, "missing argument(s)")
    end

    test "Unary operators allow 1 or more arguments" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :-, value: "-"},
         %Token{line: 1, pos: 4, type: :number, value: "1"},
         %Token{line: 1, pos: 5, type: :cparen, value: ")"}]
      assert {:ok, _} = Parser.parse(tokens)

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :-, value: "-"},
         %Token{line: 1, pos: 4, type: :number, value: "1"},
         %Token{line: 1, pos: 6, type: :number, value: "2"},
         %Token{line: 1, pos: 7, type: :cparen, value: ")"}]
      assert {:ok, _} = Parser.parse(tokens)

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :-, value: "-"},
         %Token{line: 1, pos: 4, type: :number, value: "1"},
         %Token{line: 1, pos: 6, type: :number, value: "2"},
         %Token{line: 1, pos: 8, type: :number, value: "3"},
         %Token{line: 1, pos: 9, type: :cparen, value: ")"}]
      assert {:ok, _} = Parser.parse(tokens)
    end

    test "Lambda statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :lambda, value: "lambda"},
         %Token{line: 1, pos: 9, type: :oparen, value: "("},
         %Token{line: 1, pos: 10, type: :identifier, value: "a"},
         %Token{line: 1, pos: 12, type: :identifier, value: "b"},
         %Token{line: 1, pos: 13, type: :cparen, value: ")"},
         %Token{line: 1, pos: 15, type: :oparen, value: "("},
         %Token{line: 1, pos: 16, type: :*, value: "*"},
         %Token{line: 1, pos: 18, type: :identifier, value: "a"},
         %Token{line: 1, pos: 20, type: :identifier, value: "b"},
         %Token{line: 1, pos: 21, type: :cparen, value: ")"},
         %Token{line: 1, pos: 22, type: :cparen, value: ")"},
         %Token{line: 2, pos: 7, type: :oparen, value: "("},
         %Token{line: 2, pos: 8, type: :lambda, value: "lambda"},
         %Token{line: 2, pos: 14, type: :*, value: "*"},
         %Token{line: 2, pos: 16, type: :oparen, value: "("},
         %Token{line: 2, pos: 17, type: :cparen, value: ")"},
         %Token{line: 2, pos: 19, type: :identifier, value: "this"},
         %Token{line: 2, pos: 23, type: :cparen, value: ")"},
         %Token{line: 3, pos: 7, type: :oparen, value: "("},
         %Token{line: 3, pos: 8, type: :lambda, value: "lambda"},
         %Token{line: 3, pos: 15, type: :identifier, value: "named"},
         %Token{line: 3, pos: 21, type: :oparen, value: "("},
         %Token{line: 3, pos: 22, type: :cparen, value: ")"},
         %Token{line: 3, pos: 24, type: :number, value: "5"},
         %Token{line: 3, pos: 25, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Lambda{name: nil,
                    lexical_this?: true,
                    parameters: ["a", "b"],
                    body: [%AST.Expression{operator: :*,
                                           arguments: [
                                             %AST.Identifier{name: "a"},
                                             %AST.Identifier{name: "b"},
                                           ]}]},
        %AST.Lambda{name: nil, lexical_this?: false, parameters: [],
                    body: [%AST.Identifier{name: "this"}]},
        %AST.Lambda{name: "named", lexical_this?: true, parameters: [],
                    body: [%AST.Number{value: "5"}]}
      ] === ast
    end

    test "Define statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 7, type: :oparen, value: "("},
         %Token{line: 1, pos: 8, type: :define, value: "define"},
         %Token{line: 1, pos: 15, type: :identifier, value: "a"},
         %Token{line: 1, pos: 17, type: :number, value: "5"},
         %Token{line: 1, pos: 18, type: :cparen, value: ")"},
         %Token{line: 2, pos: 7, type: :oparen, value: "("},
         %Token{line: 2, pos: 8, type: :define, value: "define"},
         %Token{line: 2, pos: 15, type: :identifier, value: "a"},
         %Token{line: 2, pos: 17, type: :number, value: "5"},
         %Token{line: 2, pos: 19, type: :identifier, value: "b"},
         %Token{line: 2, pos: 21, type: :number, value: "6"},
         %Token{line: 2, pos: 23, type: :identifier, value: "c"},
         %Token{line: 2, pos: 25, type: :number, value: "7"},
         %Token{line: 2, pos: 26, type: :cparen, value: ")"},
         %Token{line: 3, pos: 7, type: :oparen, value: "("},
         %Token{line: 3, pos: 8, type: :define, value: "define"},
         %Token{line: 3, pos: 14, type: :*, value: "*"},
         %Token{line: 3, pos: 16, type: :identifier, value: "b"},
         %Token{line: 3, pos: 18, type: :number, value: "6"},
         %Token{line: 3, pos: 19, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Define{name: "a", value: %AST.Number{value: "5"}, default?: false},
        [
          %AST.Define{name: "a", value: %AST.Number{value: "5"}, default?: false},
          %AST.Define{name: "b", value: %AST.Number{value: "6"}, default?: false},
          %AST.Define{name: "c", value: %AST.Number{value: "7"}, default?: false},
        ],
        %AST.Define{name: "b", value: %AST.Number{value: "6"}, default?: true},
      ] === ast
    end

    test "Use statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :use, value: "use"},
         %Token{line: 1, pos: 6, type: :string, value: "http"},
         %Token{line: 1, pos: 10, type: :cparen, value: ")"},
         %Token{line: 1, pos: 12, type: :oparen, value: "("},
         %Token{line: 1, pos: 13, type: :use, value: "use"},
         %Token{line: 1, pos: 16, type: :*, value: "*"},
         %Token{line: 1, pos: 18, type: :string, value: "http"},
         %Token{line: 1, pos: 23, type: :quote, value: "'"},
         %Token{line: 1, pos: 24, type: :identifier, value: "myhttp"},
         %Token{line: 1, pos: 30, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Use{module: "http", name: "http"},
        %AST.Use{module: "http", name: "myhttp"}
      ] === ast
    end

    test "Use statements error accordingly" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :use, value: "use"},
         %Token{line: 1, pos: 5, type: :cparen, value: ")"}]
      assert {:error, _} = Parser.parse(tokens)

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :use, value: "use"},
         %Token{line: 1, pos: 5, type: :*, value: "*"},
         %Token{line: 1, pos: 7, type: :string, value: "http"},
         %Token{line: 1, pos: 12, type: :identifier, value: "myhttp"},
         %Token{line: 1, pos: 18, type: :cparen, value: ")"}]
      assert {:error, _} = Parser.parse(tokens)

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :use, value: "use"},
         %Token{line: 1, pos: 5, type: :*, value: "*"},
         %Token{line: 1, pos: 7, type: :string, value: "http"},
         %Token{line: 1, pos: 11, type: :cparen, value: ")"}]
      assert {:error, _} = Parser.parse(tokens)

      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :use, value: "use"},
         %Token{line: 1, pos: 5, type: :*, value: "*"},
         %Token{line: 1, pos: 7, type: :string, value: "http"},
         %Token{line: 1, pos: 12, type: :quote, value: "'"},
         %Token{line: 1, pos: 13, type: :identifier, value: "myhttp"},
         %Token{line: 1, pos: 20, type: :string, value: "extra string"},
         %Token{line: 1, pos: 32, type: :cparen, value: ")"}]
      assert {:error, _} = Parser.parse(tokens)
    end

    test "If statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :if, value: "if"},
         %Token{line: 1, pos: 5, type: :oparen, value: "("},
         %Token{line: 1, pos: 6, type: :not, value: "not"},
         %Token{line: 1, pos: 10, type: true, value: "true"},
         %Token{line: 1, pos: 14, type: :cparen, value: ")"},
         %Token{line: 1, pos: 16, type: :identifier, value: "something-wrong"},
         %Token{line: 1, pos: 31, type: :cparen, value: ")"},
         %Token{line: 2, pos: 7, type: :oparen, value: "("},
         %Token{line: 2, pos: 8, type: :if, value: "if"},
         %Token{line: 2, pos: 11, type: :oparen, value: "("},
         %Token{line: 2, pos: 12, type: :eq, value: "eq"},
         %Token{line: 2, pos: 15, type: :string, value: "pie"},
         %Token{line: 2, pos: 19, type: :string, value: "cake"},
         %Token{line: 2, pos: 23, type: :cparen, value: ")"},
         %Token{line: 3, pos: 9, type: :string, value: "what?"},
         %Token{line: 4, pos: 9, type: :string, value: "thought so"},
         %Token{line: 4, pos: 19, type: :cparen, value: ")"}]
      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.If{condition: %AST.Expression{operator: :not,
                                           arguments: [%AST.Bool{value: "true"}]},
                true_body: %AST.Identifier{name: "something-wrong"}},
        %AST.If{
          condition: %AST.Expression{operator: :eq,
                                     arguments: [
                                       %AST.String{value: "pie"},
                                       %AST.String{value: "cake"}
                                     ]},
          true_body: %AST.String{value: "what?"},
          false_body: %AST.String{value: "thought so"}}
      ] === ast
    end

    test "Ternary statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :ternary, value: "?:"},
         %Token{line: 1, pos: 5, type: :oparen, value: "("},
         %Token{line: 1, pos: 6, type: :eq, value: "eq"},
         %Token{line: 1, pos: 9, type: :number, value: "2"},
         %Token{line: 1, pos: 11, type: :number, value: "2"},
         %Token{line: 1, pos: 12, type: :cparen, value: ")"},
         %Token{line: 1, pos: 14, type: :quote, value: "'"},
         %Token{line: 1, pos: 15, type: :identifier, value: "ok"},
         %Token{line: 1, pos: 18, type: :quote, value: "'"},
         %Token{line: 1, pos: 19, type: :identifier, value: "world-on-fire"},
         %Token{line: 1, pos: 32, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Ternary{
          condition: %AST.Expression{operator: :eq,
                                     arguments: [%AST.Number{value: "2"},
                                                 %AST.Number{value: "2"}]},
          true_body: %AST.Symbol{name: "ok"},
          false_body: %AST.Symbol{name: "world-on-fire"}}
      ] === ast
    end

    test "Defun statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :defun, value: "defun"},
         %Token{line: 1, pos: 8, type: :identifier, value: "factorial"},
         %Token{line: 1, pos: 18, type: :oparen, value: "("},
         %Token{line: 1, pos: 19, type: :identifier, value: "n"},
         %Token{line: 1, pos: 20, type: :cparen, value: ")"},
         %Token{line: 2, pos: 9, type: :oparen, value: "("},
         %Token{line: 2, pos: 10, type: :if, value: "if"},
         %Token{line: 2, pos: 13, type: :oparen, value: "("},
         %Token{line: 2, pos: 14, type: :eq, value: "eq"},
         %Token{line: 2, pos: 17, type: :identifier, value: "n"},
         %Token{line: 2, pos: 19, type: :number, value: "0"},
         %Token{line: 2, pos: 20, type: :cparen, value: ")"},
         %Token{line: 3, pos: 11, type: :number, value: "0"},
         %Token{line: 4, pos: 11, type: :oparen, value: "("},
         %Token{line: 4, pos: 12, type: :*, value: "*"},
         %Token{line: 4, pos: 14, type: :identifier, value: "x"},
         %Token{line: 4, pos: 16, type: :oparen, value: "("},
         %Token{line: 4, pos: 17, type: :identifier, value: "fact"},
         %Token{line: 4, pos: 22, type: :oparen, value: "("},
         %Token{line: 4, pos: 23, type: :-, value: "-"},
         %Token{line: 4, pos: 25, type: :identifier, value: "x"},
         %Token{line: 4, pos: 27, type: :number, value: "1"},
         %Token{line: 4, pos: 28, type: :cparen, value: ")"},
         %Token{line: 4, pos: 29, type: :cparen, value: ")"},
         %Token{line: 4, pos: 30, type: :cparen, value: ")"},
         %Token{line: 4, pos: 31, type: :cparen, value: ")"},
         %Token{line: 4, pos: 32, type: :cparen, value: ")"},
         %Token{line: 6, pos: 7, type: :oparen, value: "("},
         %Token{line: 6, pos: 8, type: :defun, value: "defun"},
         %Token{line: 6, pos: 14, type: :identifier, value: "is-5"},
         %Token{line: 6, pos: 19, type: :oparen, value: "("},
         %Token{line: 6, pos: 20, type: :identifier, value: "n"},
         %Token{line: 6, pos: 21, type: :cparen, value: ")"},
         %Token{line: 7, pos: 9, type: :oparen, value: "("},
         %Token{line: 7, pos: 10, type: :define, value: "define"},
         %Token{line: 7, pos: 17, type: :identifier, value: "x"},
         %Token{line: 7, pos: 19, type: :number, value: "5"},
         %Token{line: 7, pos: 20, type: :cparen, value: ")"},
         %Token{line: 8, pos: 9, type: :oparen, value: "("},
         %Token{line: 8, pos: 10, type: :eq, value: "eq"},
         %Token{line: 8, pos: 13, type: :identifier, value: "n"},
         %Token{line: 8, pos: 15, type: :number, value: "5"},
         %Token{line: 8, pos: 16, type: :cparen, value: ")"},
         %Token{line: 8, pos: 17, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Defun{
          name: "factorial",
          parameters: ["n"],
          body: [%AST.If{
            condition: %AST.Expression{
              operator: :eq,
              arguments: [%AST.Identifier{name: "n"}, %AST.Number{value: "0"}]},
            true_body: %AST.Number{value: "0"},
            false_body: %AST.Expression{
              operator: :*,
              arguments: [
                %AST.Identifier{name: "x"},
                [%AST.Identifier{name: "fact"},
                 %AST.Expression{
                   operator: :-,
                   arguments: [%AST.Identifier{name: "x"},
                               %AST.Number{value: "1"}]}
                ]
              ]
            }
          }]
        },
        %AST.Defun{
          name: "is-5",
          parameters: ["n"],
          body: [
            %AST.Define{name: "x", value: %AST.Number{value: "5"},
                          default?: false},
            %AST.Expression{operator: :eq,
                            arguments: [%AST.Identifier{name: "n"},
                                        %AST.Number{value: "5"}]},
          ]
        }
      ] === ast
    end

    test "Object literals are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :object, value: "object"},
         %Token{line: 1, pos: 9, type: :quote, value: "'"},
         %Token{line: 1, pos: 10, type: :identifier, value: "n"},
         %Token{line: 1, pos: 12, type: :number, value: "5"},
         %Token{line: 1, pos: 14, type: :quote, value: "'"},
         %Token{line: 1, pos: 15, type: :identifier, value: "m"},
         %Token{line: 1, pos: 17, type: :number, value: "10"},
         %Token{line: 1, pos: 19, type: :cparen, value: ")"},
         %Token{line: 2, pos: 7, type: :oparen, value: "("},
         %Token{line: 2, pos: 8, type: :object, value: "object"},
         %Token{line: 2, pos: 14, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Object{
          value: [
            {%AST.Symbol{name: "n"}, %AST.Number{value: "5"}},
            {%AST.Symbol{name: "m"}, %AST.Number{value: "10"}}
          ]
        },
        %AST.Object{value: []}
      ] === ast
    end

    test "Return statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :return, value: "return"},
         %Token{line: 1, pos: 8, type: :cparen, value: ")"},
         %Token{line: 2, pos: 7, type: :oparen, value: "("},
         %Token{line: 2, pos: 8, type: :return, value: "return"},
         %Token{line: 2, pos: 15, type: :identifier, value: "a"},
         %Token{line: 2, pos: 16, type: :cparen, value: ")"},
         %Token{line: 3, pos: 7, type: :oparen, value: "("},
         %Token{line: 3, pos: 8, type: :return, value: "return"},
         %Token{line: 3, pos: 15, type: :oparen, value: "("},
         %Token{line: 3, pos: 16, type: :lambda, value: "lambda"},
         %Token{line: 3, pos: 23, type: :oparen, value: "("},
         %Token{line: 3, pos: 24, type: :identifier, value: "x"},
         %Token{line: 3, pos: 25, type: :cparen, value: ")"},
         %Token{line: 3, pos: 27, type: :oparen, value: "("},
         %Token{line: 3, pos: 28, type: :+, value: "+"},
         %Token{line: 3, pos: 30, type: :identifier, value: "x"},
         %Token{line: 3, pos: 32, type: :number, value: "1"},
         %Token{line: 3, pos: 33, type: :cparen, value: ")"},
         %Token{line: 3, pos: 34, type: :cparen, value: ")"},
         %Token{line: 3, pos: 35, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Return{value: nil},
        %AST.Return{value: %AST.Identifier{name: "a"}},
        %AST.Return{
          value: %AST.Lambda{
            parameters: ["x"],
            lexical_this?: true,
            body: [
              %AST.Expression{
                operator: :+,
                arguments: [
                  %AST.Identifier{name: "x"},
                  %AST.Number{value: "1"}
                ]}
            ]
          }
        }
      ] === ast
    end

    test "Cond statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :cond, value: "cond"},
         %Token{line: 2, pos: 9, type: :oparen, value: "("},
         %Token{line: 2, pos: 10, type: :eq, value: "eq"},
         %Token{line: 2, pos: 13, type: :string, value: "a"},
         %Token{line: 2, pos: 15, type: :string, value: "b"},
         %Token{line: 2, pos: 16, type: :cparen, value: ")"},
         %Token{line: 3, pos: 11, type: :number, value: "1"},
         %Token{line: 4, pos: 9, type: :oparen, value: "("},
         %Token{line: 4, pos: 10, type: :eq, value: "eq"},
         %Token{line: 4, pos: 13, type: :string, value: "c"},
         %Token{line: 4, pos: 15, type: :string, value: "d"},
         %Token{line: 4, pos: 16, type: :cparen, value: ")"},
         %Token{line: 5, pos: 11, type: :number, value: "2"},
         %Token{line: 6, pos: 9, type: :oparen, value: "("},
         %Token{line: 6, pos: 10, type: :eq, value: "eq"},
         %Token{line: 6, pos: 13, type: :number, value: "5"},
         %Token{line: 6, pos: 15, type: :number, value: "5"},
         %Token{line: 6, pos: 16, type: :cparen, value: ")"},
         %Token{line: 7, pos: 11, type: true, value: "true"},
         %Token{line: 8, pos: 9, type: :quote, value: "'"},
         %Token{line: 8, pos: 10, type: :identifier, value: "otherwise"},
         %Token{line: 9, pos: 11, type: false, value: "false"},
         %Token{line: 9, pos: 16, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.Condition{
          conditions: [
            {
              %AST.Expression{operator: :eq,
                              arguments: [%AST.String{value: "a"},
                                          %AST.String{value: "b"}]},
              %AST.Number{value: "1"}
            },
            {
              %AST.Expression{operator: :eq,
                              arguments: [%AST.String{value: "c"},
                                          %AST.String{value: "d"}]},
              %AST.Number{value: "2"}
            },
            {
              %AST.Expression{operator: :eq,
                              arguments: [%AST.Number{value: "5"},
                                          %AST.Number{value: "5"}]},
              %AST.Bool{value: "true"}
            },
            {
              %AST.Symbol{name: "otherwise"},
              %AST.Bool{value: "false"}
            }
          ]
        }
      ] === ast
    end

    test "Loop statements are parsed" do
      tokens =
        [%Token{line: 1, pos: 1, type: :oparen, value: "("},
         %Token{line: 1, pos: 2, type: :loop, value: "loop"},
         %Token{line: 1, pos: 7, type: :oparen, value: "("},
         %Token{line: 1, pos: 8, type: :oparen, value: "("},
         %Token{line: 1, pos: 9, type: :define, value: "define"},
         %Token{line: 1, pos: 16, type: :identifier, value: "i"},
         %Token{line: 1, pos: 18, type: :number, value: "0"},
         %Token{line: 1, pos: 19, type: :cparen, value: ")"},
         %Token{line: 1, pos: 21, type: :oparen, value: "("},
         %Token{line: 1, pos: 22, type: :<=, value: "<="},
         %Token{line: 1, pos: 25, type: :identifier, value: "i"},
         %Token{line: 1, pos: 27, type: :number, value: "10"},
         %Token{line: 1, pos: 29, type: :cparen, value: ")"},
         %Token{line: 1, pos: 31, type: :oparen, value: "("},
         %Token{line: 1, pos: 32, type: :++, value: "++"},
         %Token{line: 1, pos: 35, type: :identifier, value: "i"},
         %Token{line: 1, pos: 36, type: :cparen, value: ")"},
         %Token{line: 1, pos: 37, type: :cparen, value: ")"},
         %Token{line: 2, pos: 9, type: :oparen, value: "("},
         %Token{line: 2, pos: 10, type: :identifier, value: "console/log"},
         %Token{line: 2, pos: 22, type: :identifier, value: "i"},
         %Token{line: 2, pos: 23, type: :cparen, value: ")"},
         %Token{line: 2, pos: 24, type: :cparen, value: ")"},
         %Token{line: 4, pos: 7, type: :oparen, value: "("},
         %Token{line: 4, pos: 8, type: :loop, value: "loop"},
         %Token{line: 4, pos: 13, type: :oparen, value: "("},
         %Token{line: 4, pos: 14, type: :<, value: "<"},
         %Token{line: 4, pos: 16, type: :identifier, value: "i"},
         %Token{line: 4, pos: 18, type: :number, value: "100"},
         %Token{line: 4, pos: 21, type: :cparen, value: ")"},
         %Token{line: 5, pos: 9, type: :oparen, value: "("},
         %Token{line: 5, pos: 10, type: :identifier, value: "console/log"},
         %Token{line: 5, pos: 22, type: :identifier, value: "i"},
         %Token{line: 5, pos: 23, type: :cparen, value: ")"},
         %Token{line: 6, pos: 9, type: :oparen, value: "("},
         %Token{line: 6, pos: 10, type: :++, value: "++"},
         %Token{line: 6, pos: 13, type: :identifier, value: "i"},
         %Token{line: 6, pos: 14, type: :cparen, value: ")"},
         %Token{line: 6, pos: 15, type: :cparen, value: ")"}]

      {:ok, ast} = Parser.parse(tokens)

      assert [
        %AST.For{
          initialization: %AST.Define{
            name: "i",
            value: %AST.Number{value: "0"},
            default?: false
          },
          condition: %AST.Expression{operator: :<=,
                                     arguments: [%AST.Identifier{name: "i"},
                                                 %AST.Number{value: "10"}]},
          final_expression: %AST.Expression{operator: :++,
                                            arguments: [%AST.Identifier{name: "i"}]},
          body: [
            [%AST.Identifier{name: "console/log"}, %AST.Identifier{name: "i"}]]
        },

        %AST.While{
          condition: %AST.Expression{
            operator: :<,
            arguments: [%AST.Identifier{name: "i"}, %AST.Number{value: "100"}]
          },
          body: [
            [%AST.Identifier{name: "console/log"}, %AST.Identifier{name: "i"}],
            %AST.Expression{operator: :++, arguments: [%AST.Identifier{name: "i"}]}
          ]
        }
      ] === ast
    end
  end

  test "Case statements are parsed" do
    tokens =
      [%Token{line: 1, pos: 1, type: :oparen, value: "("},
       %Token{line: 1, pos: 2, type: :case, value: "case"},
       %Token{line: 1, pos: 7, type: :identifier, value: "a"},
       %Token{line: 2, pos: 7, type: :oparen, value: "("},
       %Token{line: 2, pos: 8, type: :quote, value: "'"},
       %Token{line: 2, pos: 9, type: :identifier, value: "b"},
       %Token{line: 2, pos: 11, type: :number, value: "5"},
       %Token{line: 2, pos: 12, type: :cparen, value: ")"},
       %Token{line: 3, pos: 7, type: :oparen, value: "("},
       %Token{line: 3, pos: 8, type: :quote, value: "'"},
       %Token{line: 3, pos: 9, type: :identifier, value: "c"},
       %Token{line: 3, pos: 11, type: :number, value: "10"},
       %Token{line: 3, pos: 13, type: :cparen, value: ")"},
       %Token{line: 4, pos: 7, type: :oparen, value: "("},
       %Token{line: 4, pos: 8, type: :quote, value: "'"},
       %Token{line: 4, pos: 9, type: :identifier, value: "default"},
       %Token{line: 4, pos: 17, type: :number, value: "50"},
       %Token{line: 4, pos: 19, type: :cparen, value: ")"},
       %Token{line: 4, pos: 20, type: :cparen, value: ")"}]

    {:ok, ast} = Parser.parse(tokens)

    assert [
      %AST.Case{
        match: %AST.Identifier{name: "a"},
        cases: [
          [%Mi.AST.Symbol{name: "b"}, %Mi.AST.Number{value: "5"}],
          [%Mi.AST.Symbol{name: "c"}, %Mi.AST.Number{value: "10"}],
          [%Mi.AST.Symbol{name: "default"}, %Mi.AST.Number{value: "50"}]
       ]}
    ] === ast
  end

  test "Throw statements are parsed" do
    tokens =
      [%Token{line: 1, pos: 1, type: :oparen, value: "("},
       %Token{line: 1, pos: 2, type: :throw, value: "throw"},
       %Token{line: 1, pos: 8, type: :oparen, value: "("},
       %Token{line: 1, pos: 9, type: :new, value: "new"},
       %Token{line: 1, pos: 13, type: :oparen, value: "("},
       %Token{line: 1, pos: 14, type: :identifier, value: "Error"},
       %Token{line: 1, pos: 20, type: :string, value: "oh no!"},
       %Token{line: 1, pos: 26, type: :cparen, value: ")"},
       %Token{line: 1, pos: 27, type: :cparen, value: ")"},
       %Token{line: 1, pos: 28, type: :cparen, value: ")"},
       %Token{line: 2, pos: 5, type: :oparen, value: "("},
       %Token{line: 2, pos: 6, type: :throw, value: "throw"},
       %Token{line: 2, pos: 12, type: :quote, value: "'"},
       %Token{line: 2, pos: 13, type: :identifier, value: "panic"},
       %Token{line: 2, pos: 18, type: :cparen, value: ")"}]

    {:ok, ast} = Parser.parse(tokens)

    assert [
      %AST.Throw{
        expression: %AST.Expression{
          operator: :new,
          arguments: [
            [%AST.Identifier{name: "Error"}, %AST.String{value: "oh no!"}]
          ]
      }},
      %AST.Throw{
        expression: %AST.Symbol{name: "panic"}
      }
    ] === ast
  end

  test "Try catch statements are parsed" do
    tokens =
      [%Token{line: 1, pos: 1, type: :oparen, value: "("},
       %Token{line: 1, pos: 2, type: :try, value: "try"},
       %Token{line: 2, pos: 7, type: :oparen, value: "("},
       %Token{line: 2, pos: 8, type: :throw, value: "throw"},
       %Token{line: 2, pos: 14, type: :oparen, value: "("},
       %Token{line: 2, pos: 15, type: :new, value: "new"},
       %Token{line: 2, pos: 19, type: :oparen, value: "("},
       %Token{line: 2, pos: 20, type: :identifier, value: "Error"},
       %Token{line: 2, pos: 26, type: :string, value: "oops"},
       %Token{line: 2, pos: 30, type: :cparen, value: ")"},
       %Token{line: 2, pos: 31, type: :cparen, value: ")"},
       %Token{line: 2, pos: 32, type: :cparen, value: ")"},
       %Token{line: 3, pos: 5, type: :oparen, value: "("},
       %Token{line: 3, pos: 6, type: :catch, value: "catch"},
       %Token{line: 3, pos: 12, type: :identifier, value: "e"},
       %Token{line: 3, pos: 13, type: :cparen, value: ")"},
       %Token{line: 4, pos: 7, type: :oparen, value: "("},
       %Token{line: 4, pos: 8, type: :identifier, value: "console/log"},
       %Token{line: 4, pos: 20, type: :identifier, value: "e"},
       %Token{line: 4, pos: 21, type: :cparen, value: ")"},
       %Token{line: 5, pos: 5, type: :finally, value: "finally"},
       %Token{line: 6, pos: 7, type: :oparen, value: "("},
       %Token{line: 6, pos: 8, type: :identifier, value: "console/log"},
       %Token{line: 6, pos: 20, type: :string, value: "Done"},
       %Token{line: 6, pos: 24, type: :cparen, value: ")"},
       %Token{line: 6, pos: 25, type: :cparen, value: ")"},
       %Token{line: 8, pos: 5, type: :oparen, value: "("},
       %Token{line: 8, pos: 6, type: :try, value: "try"},
       %Token{line: 9, pos: 7, type: :identifier, value: "a"},
       %Token{line: 10, pos: 5, type: :oparen, value: "("},
       %Token{line: 10, pos: 6, type: :catch, value: "catch"},
       %Token{line: 10, pos: 12, type: :identifier, value: "e"},
       %Token{line: 10, pos: 13, type: :cparen, value: ")"},
       %Token{line: 11, pos: 7, type: :identifier, value: "b"},
       %Token{line: 11, pos: 8, type: :cparen, value: ")"}]

    {:ok, ast} = Parser.parse(tokens)

    assert [
      %AST.Try{
        body: %AST.Throw{
          expression: %AST.Expression{
            operator: :new,
            arguments: [
              [%AST.Identifier{name: "Error"}, %AST.String{value: "oops"}]
            ]}
        },
        catch_expression: %AST.Identifier{name: "e"},
        catch_body: [%AST.Identifier{name: "console/log"},
                     %AST.Identifier{name: "e"}],
        finally_body: [%AST.Identifier{name: "console/log"},
                       %AST.String{value: "Done"}],
      },
      %AST.Try{
        body: %AST.Identifier{name: "a"},
        catch_expression: %AST.Identifier{name: "e"},
        catch_body: %AST.Identifier{name: "b"}
      }
    ] === ast
  end
end
