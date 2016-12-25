defmodule Mi.Parser do
  @moduledoc """
  The parser will generate an abstract syntax tree representing the program's
  structure.
  """

  require Integer

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

  @statements [:lambda, :define, :use, :if, :ternary, :defun, :object]

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
  defp do_parse(%Parser{tokens: [%Token{type: :oparen} | rest]} = parser) do
    case parse_list(rest) do
      {:error, reason} -> {:error, reason}
      {:ok, rest, node} ->
        do_parse(%{parser | tokens: rest, ast: [node | parser.ast]})
    end
  end
  defp do_parse(%Parser{tokens: [%Token{type: :cparen} = token | _]}) do
    error(token, "mismatched `)'")
  end
  defp do_parse(%Parser{tokens: [token | _]}) do
    error(token, "unexpected token `#{token}', expecting `('")
  end

  @spec parse_list([Token.t]) :: tree_result
  defp parse_list([%Token{type: type} = token | rest])
  when is_operator(type),
    do: parse_expression(rest, token)
  defp parse_list([%Token{type: type} | _] = tokens)
  when is_statement(type),
    do: parse_statement(tokens)
  defp parse_list(tokens),
    do: parse_list(tokens, [])

  @spec parse_list([Token.t], [AST.tnode], boolean) :: tree_result
  defp parse_list(tokens, list, literal \\ false)
  defp parse_list([%Token{type: :cparen} | rest], list, true) do
    {:ok, rest, %AST.List{items: Enum.reverse(list)}}
  end
  defp parse_list([%Token{type: :cparen} | rest], list, false) do
    {:ok, rest, list |> Enum.reverse |> List.flatten}
  end
  defp parse_list(tokens, list, literal?) do
    case parse_atom(tokens) do
      {:error, message} -> {:error, message}
      {:ok, rest, node} ->
        parse_list(rest, [node | list], literal?)
    end
  end

  @spec parse_atom([Token.t]) :: tree_result | node_result
  defp parse_atom([%Token{type: :quote}, token | rest]) do
    # Quoted atom sometimes have a special case, otherwise it's just ignored
    case token.type do
      :oparen     -> parse_list(rest, [], true)
      :identifier -> {:ok, rest, %AST.Symbol{name: token.value}}
      :number     -> {:ok, rest, %AST.Symbol{name: token.value}}
      _           ->
        # TODO: warn about unnecessary quote
        parse_atom([token | rest])
    end
  end
  defp parse_atom([token | rest]) do
    case token.type do
      :oparen     -> parse_list(rest)
      :identifier -> {:ok, rest, %AST.Identifier{name: token.value}}
      :number     -> {:ok, rest, %AST.Number{value: token.value}}
      :string     -> {:ok, rest, %AST.String{value: token.value}}
      :true       -> {:ok, rest, %AST.Bool{value: "true"}}
      :false      -> {:ok, rest, %AST.Bool{value: "false"}}
      :nil        -> {:ok, rest, %AST.Nil{}}
      _           -> error(token, "unexpected token `#{token}'")
    end
  end

  @spec parse_statement([Token.t]) :: node_result
  defp parse_statement([%Token{type: type} = token | rest]) do
    case type do
      :lambda  -> parse_lambda(rest)
      :define  -> parse_define(rest)
      :use     -> parse_use(rest)
      :object  -> parse_object(rest)
      :if      -> parse_if(rest)
      :ternary -> parse_ternary(rest)
      :defun   -> parse_defun(rest)
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
    case parse_atom(tokens) do
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
    case parse_atom(tokens) do
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

  @spec parse_define([Token.t]) :: node_result
  defp parse_define([%Token{type: :*} | rest]) do
    parse_define(rest, true)
  end
  @spec parse_define([Token.t], boolean) :: node_result
  defp parse_define(tokens, default? \\ false) do
    with {:ok, rest, name}  <- expect(tokens, :identifier),
         {:ok, rest, value} <- parse_atom(rest),
         {:ok, rest, _}     <- expect(rest, ")"),
      do: {:ok, rest, %AST.Variable{name: name.value, value: value,
                                    default?: default?}}
  end

  @spec parse_use([Token.t]) :: node_result
  defp parse_use([%Token{type: :*} | rest]) do
    # TODO: improve error messages here. currently throws errors about
    #       unexpected )
    with {:ok, rest, module} <- expect(rest, :string),
         {:ok, rest, %AST.Symbol{name: name}} <- parse_atom(rest),
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
    with {:ok, rest, condition} <- parse_atom(tokens),
         {:ok, rest, true_body} <- parse_atom(rest) do
      case rest do
        [%Token{type: :cparen} | rest] ->
          {:ok, rest, %AST.If{condition: condition, true_body: true_body}}
        _ ->
          with {:ok, rest, false_body} <- parse_atom(rest),
               {:ok, rest, _}          <- expect(rest, ")"),
            do: {:ok, rest, %AST.If{condition: condition, true_body: true_body,
                                    false_body: false_body}}
      end
    end
  end

  @spec parse_ternary([Token.t]) :: node_result
  defp parse_ternary(tokens) do
    with {:ok, rest, condition}  <- parse_atom(tokens),
         {:ok, rest, true_body}  <- parse_atom(rest),
         {:ok, rest, false_body} <- parse_atom(rest),
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

  defp parse_object([token | _] = tokens) do
    with {:ok, rest, value} when is_list(value) <- parse_list(tokens) do
      if Integer.is_even(length(value)) do
        {:ok, rest, %AST.Object{value: value}}
      else
        error(token, "invalid amount of arguments for object (must be even)")
      end
    end
  end
end
