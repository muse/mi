defmodule Mi.Utils do
  alias IO.ANSI, as: Output

  def error(type, message) do
    IO.puts :stderr, [Output.red, Output.bright, "#{type} error:",
                      Output.reset, " #{message}"]
  end

  def warning(message) do
    IO.puts :stderr, [Output.yellow, Output.bright, "warning:",
                      Output.reset, " #{message}"]
  end

  def fatal_error(type, message) do
    error(type, message)
    System.halt(1)
  end
end
