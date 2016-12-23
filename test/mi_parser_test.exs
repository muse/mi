defmodule MiParserTest do
  alias Mi.{Parser, AST}
  use   ExUnit.Case

  describe "&Parser.parse/1" do
    test "Literal lists are parsed" do
      {:ok, ast} = Parser.parse("('(1 \"ok\" 3 4) '() '('()))")

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
      {:ok, ast} = Parser.parse("(+ 1 2 (* 3 3))")

      assert [
        %AST.Expression{
          operator: :plus,
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
      {:error, error} = Parser.parse("(* 1)")
      assert String.contains?(error, "not enough arguments")

      {:error, error} = Parser.parse("(typeof true false)")
      assert String.contains?(error, "too many arguments")

      {:error, error} = Parser.parse("(-)")
      assert String.contains?(error, "missing argument(s)")

      assert {:ok, _} = Parser.parse("(- 1)")
      assert {:ok, _} = Parser.parse("(- 1 2)")
      assert {:ok, _} = Parser.parse("(- 1 2 3)")
    end

    test "Lambda statements are parsed" do
      {:ok, ast} = Parser.parse("""
      (lambda (a b) (* a b))
      (lambda* named () 5)
      """)

      assert [
        %AST.Lambda{name: nil,
                    args: [%AST.Identifier{name: "a"},
                           %AST.Identifier{name: "b"}],
                    body: %AST.Expression{operator: :*, arguments: [
                                             %AST.Identifier{name: "a"},
                                             %AST.Identifier{name: "b"},
                                           ]}},
        %AST.Lambda{name: "named", args: [], body: %AST.Number{value: "5"}}
      ] === ast
    end

    test "Define statements are parsed" do
      {:ok, ast} = Parser.parse("(define a 5) (define* b 6)")

      assert [
        %AST.Variable{name: "a", value: %AST.Number{value: "5"}, is_default: false},
        %AST.Variable{name: "b", value: %AST.Number{value: "6"}, is_default: true},
      ] === ast
    end

    test "Use statements are parsed" do
      {:ok, ast} = Parser.parse("(use \"http\") (use* \"http\" 'myhttp)")

      assert [
        %AST.Use{module: "http", name: "http"},
        %AST.Use{module: "http", name: "myhttp"}
      ] === ast
    end

    test "Use statements error accordingly" do
      assert {:error, _} = Parser.parse("(use)")
      assert {:error, _} = Parser.parse("(use* \"http\" myhttp)")
      assert {:error, _} = Parser.parse("(use* \"http\")")
      assert {:error, _} = Parser.parse("(use* \"http\" 'myhttp \"extra string\")")
    end

    test "If statements are parsed" do
      {:ok, ast} = Parser.parse("""
      (if (not true) something-wrong)
      (if (eq "pie" "cake")
        "what?"
        "thought so")
      """)

      assert [
        %AST.If{condition: %AST.Expression{operator: :not,
                                           arguments: [%AST.Bool{value:
                                                                 "true"}]},
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

    test "Defun statements are parsed" do
      {:ok, ast} = Parser.parse("""
      (defun factorial (n)
        (if (eq n 0)
          0
          (* x (fact (- x 1)))))
      """)

      assert [
        %AST.Function{
          name: "factorial",
          args: [%AST.Identifier{name: "n"}],
          body: %AST.If{
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
                   operator: :minus,
                   arguments: [%AST.Identifier{name: "x"},
                               %AST.Number{value: "1"}]}
                ]
              ]
            }
          }
        }
      ] === ast
    end
  end
end
