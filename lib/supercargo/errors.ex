defmodule Supercargo.TypeConstraintError do
  defexception [:message]

  def exception({type, value}) do
    %__MODULE__{message: "Expecting type #{type} but got #{value} of type bitstring."}
  end
end

defmodule Supercargo.ValueConstraintError do
  defexception [:message]

  def exception({value, regex, field, source}) do
    %__MODULE__{
      message:
        "(#{source}:#{field}) one or more characters of `#{value}` do not match the regular expression #{Regex.source(regex)}."
    }
  end
end

defmodule Supercargo.ArgumentError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Supercargo.UsageError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Supercargo.ExtractError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
