defmodule Mi.Lexer do
  @moduledoc """
  The lexer converts a sequence of characters into a sequence of tokens,
  removing unnecessary whitespace while doing so. These tokens will later be
  passed to the parser to create an abstract syntax tree which will eventually
  be used to generate Javascript.
  """

  import Mi.Token, only: :macros

  alias Mi.{Lexer, Token}

  defstruct tokens: [], line: 1, pos: 1, expr: ''

  @typep t :: %__MODULE__{
    tokens: [Token.t],
    line: pos_integer,
    pos: pos_integer,
    expr: charlist
  }

  @typep token_result :: {:ok, {charlist, charlist, Token.type}}
  @typep token_error :: {:error, String.t}

  @typep lexer_result :: {:ok, [Token.t]} | {:error, String.t}

  @spec lex(String.t) :: lexer_result
  def lex(expr), do: do_lex(%Lexer{expr: to_charlist(expr)})

  @spec error(Lexer.t, String.t) :: String.t
  defp error(lexer, message) do
    "#{lexer.line}:#{lexer.pos}: #{message}"
  end

  @spec lex_identifier(charlist, charlist) :: token_result
  defp lex_identifier(expr, acc \\ '')
  defp lex_identifier([char | rest], acc) when is_identifier_literal(char) do
    lex_identifier(rest, [char | acc])
  end
  defp lex_identifier(expr, acc) do
    acc = Enum.reverse(acc)
    type =
      cond do
        Token.keyword?(acc)  -> List.to_atom(acc)
        Token.operator?(acc) -> :operator
        :otherwise           -> :identifier
      end

    {:ok, {expr, {acc, type}}}
  end

  @spec lex_string(charlist, charlist) :: token_result | token_error
  defp lex_string(expr, acc \\ '')
  defp lex_string([], _acc) do
    {:error, "unterminated string"}
  end
  defp lex_string([?\\, char | rest], acc) do
    lex_string(rest, [char, ?\\ | acc])
  end
  defp lex_string([?" | rest], acc) do
    {:ok, {rest, {Enum.reverse(acc), :string}}}
  end
  defp lex_string([char | rest], acc) do
    lex_string(rest, [char | acc])
  end

  @spec lex_number(charlist, charlist) :: token_result
  defp lex_number(expr, acc \\ '')
  defp lex_number([char | rest], acc) when is_numeric_literal(char) do
    lex_number(rest, [char | acc])
  end
  defp lex_number(expr, acc) do
    {:ok, {expr, {Enum.reverse(acc), :number}}}
  end

  @spec lex_symbol(charlist, charlist) :: token_result
  defp lex_symbol(expr, acc \\ '')
  defp lex_symbol([char | rest], acc) when is_symbol_literal(char) do
    lex_symbol(rest, [char | acc])
  end
  defp lex_symbol(expr, acc) do
    {:ok, {expr, {Enum.reverse(acc), :symbol}}}
  end

  @spec lex_operator(charlist) :: token_result
  defp lex_operator(expr) do
    {rest, char} =
      case expr do
        [?+, ?+ | rest]     -> {rest, '++'}
        [?-, ?- | rest]     -> {rest, '--'}
        [?/, ?/ | rest]     -> {rest, '//'}
        [?*, ?* | rest]     -> {rest, '**'}
        [?<, ?< | rest]     -> {rest, '<<'}
        [?>, ?>, ?> | rest] -> {rest, '>>>'}
        [?>, ?> | rest]     -> {rest, '>>'}
        [?<, ?= | rest]     -> {rest, '<='}
        [?>, ?= | rest]     -> {rest, '>='}
        [?- = char | rest]  -> {rest, char}
        [?+ = char | rest]  -> {rest, char}
        [?/ = char | rest]  -> {rest, char}
        [?* = char | rest]  -> {rest, char}
        [?% = char | rest]  -> {rest, char}
        [?< = char | rest]  -> {rest, char}
        [?> = char | rest]  -> {rest, char}
        [?~ = char | rest]  -> {rest, char}
        [?^ = char | rest]  -> {rest, char}
        [?| = char | rest]  -> {rest, char}
        [?& = char | rest]  -> {rest, char}
      end
    {:ok, {rest, {char, :operator}}}
  end

  @spec skip_comment(charlist) :: charlist
  defp skip_comment([]), do: []
  defp skip_comment([?\n | _rest] = expr), do: expr
  defp skip_comment([_char | rest]), do: skip_comment(rest)

  @spec do_lex(Lexer.t) :: lexer_result
  defp do_lex(%Lexer{expr: []} = lexer) do
    {:ok, Enum.reverse(lexer.tokens)}
  end
  defp do_lex(%Lexer{expr: [?\n | rest]} = lexer) do
    do_lex(%{lexer | expr: rest, line: lexer.line + 1, pos: 1})
  end
  defp do_lex(%Lexer{expr: [?; | rest]} = lexer) do
    do_lex(%{lexer | expr: skip_comment(rest)})
  end
  defp do_lex(%Lexer{expr: [char | rest]} = lexer) when is_whitespace(char) do
    do_lex(%{lexer | expr: rest, pos: lexer.pos + 1})
  end
  defp do_lex(%Lexer{expr: [char | rest]} = lexer) do
    result =
      cond do
        is_operator_initiater(char) -> lex_operator(lexer.expr)
        is_numeric_literal(char) -> lex_number(lexer.expr)
        is_start_of_identifier(char) -> lex_identifier(lexer.expr)
        char === ?" -> lex_string(rest)
        char === ?: -> lex_symbol(rest)
        :otherwise ->
          case lexer.expr do
            [?( = char | rest] -> {:ok, {rest, {char, :oparen}}}
            [?) = char | rest] -> {:ok, {rest, {char, :cparen}}}
            [?' = char | rest] -> {:ok, {rest, {char, :quote}}}
            [char | _rest] ->
              {:error, "unexpected token `#{[char]}'"}
          end
      end

    case result do
      {:ok, {rest, {value, type}}} ->
        token = Token.new(lexer, value, type)
        do_lex(%{lexer |
                 expr: rest,
                 tokens: [token | lexer.tokens],
                 pos: lexer.pos + (to_string([token.value]) |> String.length)
               })
      {:error, reason} ->
        {:error, error(lexer, reason)}
    end
  end
end
