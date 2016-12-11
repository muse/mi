defmodule Mi.Lexer do
  @moduledoc """
  The lexer converts a sequence of characters into a sequence of tokens,
  removing unnecessary whitespace while doing so. These tokens will later be
  passed to the parser to create an abstract syntax tree which will eventually
  be used to generate Javascript.
  """

  import Mi.Token, only: :macros

  alias Mi.{Lexer, Token}

  @enforce_keys [:expr]
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
        is_numeric_literal(char) and char !== ?. -> lex_number(lexer.expr)
        is_start_of_identifier(char) -> lex_identifier(lexer.expr)
        char === ?" -> lex_string(rest)
        :otherwise -> lex_symbol(lexer.expr)
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
      if Token.keyword?(acc) do
        List.to_atom(acc)
      else
        :identifier
      end

    {:ok, {expr, {acc, type}}}
  end

  @spec lex_string(charlist, charlist) :: token_result | token_error
  defp lex_string(expr, acc \\ '')
  defp lex_string([], _) do
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

  @spec lex_symbol(charlist) :: token_result
  defp lex_symbol(expr) do
    case expr do
      [?. = char | rest]  -> {:ok, {rest, {char, :dot}}}
      [?( = char | rest]  -> {:ok, {rest, {char, :oparen}}}
      [?) = char | rest]  -> {:ok, {rest, {char, :cparen}}}
      [?' = char | rest]  -> {:ok, {rest, {char, :quote}}}
      [?+, ?+ | rest]     -> {:ok, {rest, {"++", :increment}}}
      [?-, ?- | rest]     -> {:ok, {rest, {"--", :decrease}}}
      [?/, ?/ | rest]     -> {:ok, {rest, {"//", :intdivide}}}
      [?*, ?* | rest]     -> {:ok, {rest, {"**", :power}}}
      [?<, ?< | rest]     -> {:ok, {rest, {"<<", :bshiftl}}}
      [?>, ?>, ?> | rest] -> {:ok, {rest, {">>>", :ubshiftr}}}
      [?>, ?> | rest]     -> {:ok, {rest, {">>", :bshiftr}}}
      [?<, ?= | rest]     -> {:ok, {rest, {"<=", :lteq}}}
      [?>, ?= | rest]     -> {:ok, {rest, {">=", :gteq}}}
      [?- = char | rest]  -> {:ok, {rest, {char, :minus}}}
      [?+ = char | rest]  -> {:ok, {rest, {char, :plus}}}
      [?/ = char | rest]  -> {:ok, {rest, {char, :divide}}}
      [?* = char | rest]  -> {:ok, {rest, {char, :*}}}
      [?% = char | rest]  -> {:ok, {rest, {char, :modulo}}}
      [?< = char | rest]  -> {:ok, {rest, {char, :lt}}}
      [?> = char | rest]  -> {:ok, {rest, {char, :gt}}}
      [?~ = char | rest]  -> {:ok, {rest, {char, :bnot}}}
      [?^ = char | rest]  -> {:ok, {rest, {char, :bxor}}}
      [?| = char | rest]  -> {:ok, {rest, {char, :bor}}}
      [?& = char | rest]  -> {:ok, {rest, {char, :band}}}
      [char | _] ->
        {:error, "invalid token `#{[char]}'"}
    end
  end

  @spec skip_comment(charlist) :: charlist
  defp skip_comment([]), do: []
  defp skip_comment([?\n | _] = expr), do: expr
  defp skip_comment([_| rest]), do: skip_comment(rest)
end
