defmodule Mi.Parser do
  @moduledoc """
  The parser will generate an abstract syntax tree representing the program's
  structure.
  """

  alias Mi.{Parser, Lexer, Token, AST}

  defstruct ast: [], tokens: []

  @type t :: %__MODULE__{
    ast: AST.t,
    tokens: [Token.t]
  }

  @type tree_result :: {[Token.t], AST.t } | {:error, String.t}
  @type node_result :: {[Token.t], AST.tnode} | {:error, String.t}

  @unary_operators [:not, :delete, :typeof, :void, :new, :++, :--,
                    :bnot, :-]

  @multi_arity_operators [:and, :or, :eq, :instanceof, :in, :"//", :"**", :"<<",
                          :>>>, :">>", :<=, :>=, :-, :+, :/, :*, :%, :<, :>, :^,
                          :|, :&, :.]

  @operators @unary_operators ++ @multi_arity_operators

  @statements [:lambda, :define, :use, :if, :ternary, :defun, :object, :return,
               :cond, :loop, :case]

  defmacrop is_unary(operator) do
    quote do: unquote(operator) in @unary_operators
  end

  defmacrop is_multi_arity(operator) do
    quote do: unquote(operator) in @multi_arity_operators
  end

  defmacrop is_operator(type) do
    quote do: unquote(type) in @operators
  end

  defmacrop is_statement(type) do
    quote do: unquote(type) in @statements
  end

  @spec error(Token.t, String.t) :: {:error, String.t}
  defp error(token, message) do
    {:error, "#{token.line}:#{token.pos}: #{message}"}
  end

  @spec expect([Token.t], atom | String.t) :: {:ok, Token.t, [Token.t]} | {:error, String.t}
  defp expect([%Token{value: value} = token | rest], expected)
  when is_binary(expected) and value === expected do
    {:ok, rest, token}
  end
  defp expect([%Token{type: type} = token | rest], expected)
  when is_atom(expected) and type === expected do
    {:ok, rest, token}
  end
  defp expect([token | _], expected) do
    error(token, "unexpected token `#{token}', expecting `#{expected}'")
  end

  @spec parse(String.t) :: {:ok, AST.t} | {:error, String.t}
  def parse(expr) do
    case Lexer.lex(expr) do
      {:ok, tokens} -> do_parse(%Parser{tokens: tokens})
      error         -> error
    end
  end

  @spec do_parse(Parser.t) :: {:ok, AST.t} | {:error, String.t}
  defp do_parse(%Parser{tokens: []} = parser) do
    {:ok, Enum.reverse(parser.ast)}
  end
  defp do_parse(%Parser{tokens: [%Token{type: :cparen} = token | _]}) do
    error(token, "mismatched `)'")
  end
  defp do_parse(%Parser{tokens: tokens} = parser) do
    case parse_sexpr(tokens) do
      {:error, reason} -> {:error, reason}
      {:ok, rest, node} ->
        do_parse(%{parser | tokens: rest, ast: [node | parser.ast]})
    end
  end

  @spec parse_sexpr([Token.t]) :: tree_result | node_result
  defp parse_sexpr([%Token{type: :oparen} | rest]), do: parse_list(rest)
  defp parse_sexpr(tokens), do: parse_atom(tokens)

  # A list can be an expression, statement or list.
  @spec parse_list([Token.t]) :: tree_result
  defp parse_list([%Token{type: type} = token | rest]) when is_operator(type),
    do: parse_expression(rest, token)
  defp parse_list([%Token{type: type} | _] = tokens) when is_statement(type),
    do: parse_statement(tokens)

  @spec parse_list([Token.t], [AST.tnode]) :: tree_result
  defp parse_list(tokens, list \\ [])
  defp parse_list([%Token{type: :cparen} | rest], list) do
    {:ok, rest, list |> Enum.reverse |> List.flatten}
  end
  defp parse_list(tokens, list) do
    case parse_sexpr(tokens) do
      {:error, message} -> {:error, message}
      {:ok, rest, node} ->
        parse_list(rest, [node | list])
    end
  end

  @spec parse_atom([Token.t]) :: tree_result | node_result
  defp parse_atom([%Token{type: :quote}, token | rest] = tokens) do
    # Quoted atoms sometimes have a special case, otherwise it's just
    # ignored
    case token.type do
      :oparen     -> parse_literal_list(tokens)
      :identifier -> {:ok, rest, %AST.Symbol{name: token.value}}
      :number     -> {:ok, rest, %AST.Symbol{name: token.value}}
      _           -> parse_atom([token | rest]) # TODO: warn about unnecessary quote
    end
  end
  defp parse_atom([token | rest]) do
    case token.type do
      :identifier -> {:ok, rest, %AST.Identifier{name: token.value}}
      :number     -> {:ok, rest, %AST.Number{value: token.value}}
      :string     -> {:ok, rest, %AST.String{value: token.value}}
      :true       -> {:ok, rest, %AST.Bool{value: "true"}}
      :false      -> {:ok, rest, %AST.Bool{value: "false"}}
      :nil        -> {:ok, rest, %AST.Nil{}}
      _           -> error(token, "expected atom, got `#{token}'")
    end
  end

  @spec parse_literal_list([Token.t]) :: node_result
  defp parse_literal_list(tokens) do
    with {:ok, rest, _}    <- expect(tokens, "'"),
         {:ok, rest, _}    <- expect(rest, "("),
         {:ok, rest, list} <- parse_list(rest, []),
      do: {:ok, rest, %AST.List{items: list}}
  end

  @spec parse_statement([Token.t]) :: node_result
  defp parse_statement([token | rest]) do
    case token.type do
      :lambda  -> parse_lambda(rest)
      :define  -> parse_define(rest)
      :use     -> parse_use(rest)
      :object  -> parse_object(rest)
      :if      -> parse_if(rest)
      :ternary -> parse_ternary(rest)
      :defun   -> parse_defun(rest)
      :return  -> parse_return(rest)
      :cond    -> parse_cond(rest)
      :loop    -> parse_loop(rest)
      :case    -> parse_case(rest)
      _        -> error(token, "unexpected token `#{token}'")
    end
  end

  @spec parse_expression([Token.t], atom, [AST.tnode]) :: node_result
  defp parse_expression(tokens, operator, arguments \\ [])
  defp parse_expression([%Token{type: :cparen} | rest], operator, arguments) do
    cond do
      length(arguments) === 0 ->
        error(operator, "missing argument(s) for `#{operator}'")
      is_unary(operator.type) and is_multi_arity(operator.type) ->
        # Operators that can have 1 or more arguments like `-`
        {:ok, rest, %AST.Expression{operator: operator.type,
                                    arguments: Enum.reverse(arguments)}}
      is_unary(operator.type) and length(arguments) > 1 ->
        error(operator, "too many arguments for `#{operator}'")
      is_multi_arity(operator.type) and length(arguments) < 2 ->
        error(operator, "not enough arguments for `#{operator}'")
      :otherwise ->
        {:ok, rest, %AST.Expression{operator: operator.type,
                                    arguments: Enum.reverse(arguments)}}
    end
  end
  defp parse_expression(tokens, operator, arguments) do
    case parse_sexpr(tokens) do
      {:error, message} -> {:error, message}
      {:ok, rest, node} -> parse_expression(rest, operator, [node | arguments])
    end
  end

  # An argument list is a list of identifiers used in lambda and function
  # definitions
  @spec parse_arg_list([Token.t]) :: [AST.Identifier.t]
  defp parse_arg_list([%Token{type: :oparen} | rest]) do
    parse_arg_list(rest, [])
  end
  defp parse_arg_list([token | _]) do
    error(token, "expecting argument list, got `#{token}'")
  end
  @spec parse_arg_list([Token.t], [String.t]) :: [String.t]
  defp parse_arg_list([%Token{type: :cparen} | rest], list) do
    {:ok, rest, Enum.reverse(list)}
  end
  defp parse_arg_list([%Token{type: :identifier} = token | rest], list) do
    parse_arg_list(rest, [token.value | list])
  end
  defp parse_arg_list([token | _], _) do
    error(token, "unexpected token `#{token}' in argument list")
  end

  # Body refers to a statement body. This is so we can do this:
  #
  # (defun is-5 (n)
  #   (define x 5)
  #   (eq n 5))
  #
  # Instead of having to wrap it in a list like this:
  #
  # (defun is-5 (n)
  #   ((define x 5)
  #    (eq n 5)))
  #
  @spec parse_body([Token.t], [AST.tnode]) :: [AST.tnode]
  defp parse_body(parser, nodes \\ [])
  defp parse_body([%Token{type: :cparen} | _] = tokens, nodes) do
    {:ok, tokens, Enum.reverse(nodes)} # Let parent functions handle `)`
  end
  defp parse_body(tokens, nodes) do
    case parse_sexpr(tokens) do
      {:error, message} -> {:error, message}
      {:ok, rest, node} -> parse_body(rest, [node | nodes])
    end
  end

  @spec parse_lambda([Token.t]) :: node_result
  defp parse_lambda([%Token{type: :*} | rest]) do
    parse_lambda(rest, false)
  end
  @spec parse_lambda([Token.t], boolean) :: node_result
  defp parse_lambda([token | rest] = tokens, lexical_this? \\ true) do
    # Check for optional name for lambda
    {name, rest} =
      case token.type do
        :identifier -> {token.value, rest}
        _           -> {nil, tokens}
      end

    with {:ok, rest, parameters} <- parse_arg_list(rest),
         {:ok, rest, body}       <- parse_body(rest),
         {:ok, rest, _}          <- expect(rest, ")"),
      do: {:ok, rest, %AST.Lambda{name: name, parameters: parameters, body: body,
                                  lexical_this?: lexical_this?}}
  end

  @spec parse_define([Token.t]) :: node_result | tree_result
  defp parse_define([%Token{type: :*} | rest]), do: do_parse_define(rest, true)
  defp parse_define(tokens), do: do_parse_define(tokens, false)

  @spec do_parse_define([Token.t], boolean, []) :: node_result | tree_result
  defp do_parse_define(tokens, default?, nodes \\ [])
  defp do_parse_define([%Token{type: :cparen} | rest], _, [node]) do
    {:ok, rest, node} # Single define, don't return a list
  end
  defp do_parse_define([%Token{type: :cparen} | rest], _, nodes) do
    {:ok, rest, nodes |> Enum.reverse |> List.flatten }
  end
  defp do_parse_define(tokens, default?, nodes) do
    with {:ok, rest, name}  <- expect(tokens, :identifier),
         {:ok, rest, value} <- parse_sexpr(rest) do
      node = %AST.Variable{name: name.value, value: value, default?: default?}
      do_parse_define(rest, default?, [node | nodes])
    end
  end

  @spec parse_use([Token.t]) :: node_result
  defp parse_use([%Token{type: :*} | rest]) do
    # TODO: improve error messages here. currently throws errors about
    #       unexpected )
    with {:ok, rest, module} <- expect(rest, :string),
         {:ok, rest, %AST.Symbol{name: name}} <- parse_sexpr(rest),
         {:ok, rest, _} <- expect(rest, ")"),
      do: {:ok, rest, %AST.Use{module: module.value, name: name}}
  end
  defp parse_use(tokens) do
    with {:ok, rest, module} <- expect(tokens, :string),
         {:ok, rest, _}      <- expect(rest, ")"),
      do: {:ok, rest, %AST.Use{module: module.value, name: module.value}}
  end

  @spec parse_if([Token.t]) :: node_result
  defp parse_if(tokens) do
    with {:ok, rest, condition} <- parse_sexpr(tokens),
         {:ok, rest, true_body} <- parse_sexpr(rest) do
      case rest do
        [%Token{type: :cparen} | rest] ->
          {:ok, rest, %AST.If{condition: condition, true_body: true_body}}
        _ ->
          with {:ok, rest, false_body} <- parse_sexpr(rest),
               {:ok, rest, _}          <- expect(rest, ")"),
            do: {:ok, rest, %AST.If{condition: condition, true_body: true_body,
                                    false_body: false_body}}
      end
    end
  end

  @spec parse_ternary([Token.t]) :: node_result
  defp parse_ternary(tokens) do
    with {:ok, rest, condition}  <- parse_sexpr(tokens),
         {:ok, rest, true_body}  <- parse_sexpr(rest),
         {:ok, rest, false_body} <- parse_sexpr(rest),
         {:ok, rest, _}          <- expect(rest, ")"),
      do: {:ok, rest, %AST.Ternary{condition: condition, true_body: true_body,
                                   false_body: false_body}}
  end

  @spec parse_defun([Token.t]) :: node_result
  defp parse_defun(tokens) do
    with {:ok, rest, name}       <- expect(tokens, :identifier),
         {:ok, rest, parameters} <- parse_arg_list(rest),
         {:ok, rest, body}       <- parse_body(rest),
         {:ok, rest, _}          <- expect(rest, ")"),
      do: {:ok, rest, %AST.Function{name: name.value, parameters: parameters,
                                    body: body}}
  end

  @spec parse_object([Token.t], [{AST.tnode, AST.tnode}]) :: node_result
  defp parse_object(tokens, object \\ [])
  defp parse_object([%Token{type: :cparen} | rest], object) do
    {:ok, rest, %AST.Object{value: Enum.reverse(object)}}
  end
  defp parse_object(tokens, object) do
    with {:ok, rest, key}   <- parse_atom(tokens),
         {:ok, rest, value} <- parse_sexpr(rest) do
      parse_object(rest, [{key, value} | object])
    end
  end

  @spec parse_return([Token.t]) :: node_result
  defp parse_return([%Token{type: :cparen} | rest]) do
    {:ok, rest, %AST.Return{value: nil}}
  end
  defp parse_return(tokens) do
    with {:ok, rest, value} <- parse_sexpr(tokens),
         {:ok, rest, _}     <- expect(rest, ")"),
      do: {:ok, rest, %AST.Return{value: value}}
  end

  @spec parse_cond([Token.t], [{AST.tnode, AST.tnode}]) :: node_result
  defp parse_cond(tokens, conditions \\ [])
  defp parse_cond([%Token{type: :cparen} | rest], conditions) do
    {:ok, rest, %AST.Condition{conditions: Enum.reverse(conditions)}}
  end
  defp parse_cond(tokens, conditions) do
    with {:ok, rest, condition} <- parse_sexpr(tokens),
         {:ok, rest, body}      <- parse_sexpr(rest) do
      parse_cond(rest, [{condition, body} | conditions])
    end
  end

  @spec parse_loop([Token.t]) :: node_result
  defp parse_loop([token | _] = tokens) do
    with {:ok, rest, head} <- parse_sexpr(tokens),
         {:ok, rest, body} <- parse_body(rest),
         {:ok, rest, _}    <- expect(rest, ")") do
      case head do
        [initialization, condition, final_expression] ->
          {:ok, rest, %AST.For{initialization: initialization,
                               condition: condition,
                               final_expression: final_expression, body: body}}
        [condition, final_expression] ->
          {:ok, rest, %AST.For{condition: condition,
                               final_expression: final_expression, body: body}}
        %{} = condition ->
          {:ok, rest, %AST.While{condition: condition, body: body}}
        _ ->
          error(token, "invalid loop head")
      end
    end
  end

  @spec parse_case([Token.t], [{AST.tnode, AST.tnode}]) :: node_result
  defp parse_case(tokens)
  defp parse_case(tokens) do
    with  {:ok, rest, match} <- parse_atom(tokens),
          {:ok, rest, cases} <- parse_case(rest, []),
      do: {:ok, rest, %AST.Case{match: match, cases: cases}}
  end
  defp parse_case([%Token{type: :cparen} | rest], cases) do
    {:ok, rest, cases}
  end
  defp parse_case(tokens, cases) do
    with  {:ok, rest, esac} <- parse_sexpr(tokens),
      do: parse_case(rest, [esac | cases])
  end
end
