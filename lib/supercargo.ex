defmodule Supercargo do
  @moduledoc """
  Disclaimer: Supercargo is currently under heavy development, so design and usage may change drastically.
 
  See https://github.com/dukeweezo/supercargo for current usage.
  """
  import Supercargo.Utils

  alias Supercargo.API
  alias Supercargo.Parser
  alias Supercargo.Parser.Validator

  defmacro __using__(_options) do
    quote do
      Module.register_attribute(__MODULE__, :maplines, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :extraction, accumulate: true, persist: false)

      import unquote(__MODULE__), only: [register_mapline: 2, extract: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    %{
      maplines: Module.get_attribute(env.module, :maplines),
      extraction: Module.get_attribute(env.module, :extraction)
    }
    |> compile
  end

  defmacro extract(entry, source) do
    quote bind_quoted: [entry: entry, source: source] do
      @extraction {entry, source}
    end
  end

  defmacro register_mapline(sources, structure) do
    quote bind_quoted: [sources: sources, structure: structure] do
      @maplines {sources, structure}
    end
  end

  defp compile(%{maplines: maplines, extraction: extraction}) do
    [{entry, source}] = extraction
    [{sources, structure}] = maplines

    Validator.validate!(sources, structure)
    vast = Parser.parse(sources, structure)

    accessors_ast =
      for token <- vast do
        Generator.run(token, sources)
      end

    api_ast =
      for source <- sources do
        generate_extract_ast(Map.to_list(entry), source)
      end

    [api_ast, accessors_ast]
  end

  defp generate_extract_ast(entry, source) do
    quote do
      # Compile-time
      def extract(unquote(source)) do
        Supercargo.extract(unquote(source), unquote(entry), [strict: false], __MODULE__)
      end

      def extract!(unquote(source)) do
        Supercargo.extract(unquote(source), unquote(entry), [strict: true], __MODULE__)
      end

      # Runtime
      def extract(unquote(source), entry) do
        Supercargo.extract(unquote(source), entry, [strict: false], __MODULE__)
      end

      def extract!(unquote(source), entry) do
        Supercargo.extract(unquote(source), entry, [strict: true], __MODULE__)
      end
    end
  end

  @doc false
  def generate_category_ast(%{source: source, category: category}) do
    quote do
      def unquote(category)(ext) do
        data = __MODULE__.unquote(construct_atomized_name([source, "__", category]))()

        Enum.reduce(data, [], fn
          {field, var}, acc ->
            match =
              Enum.find(
                ext,
                fn {key, _} ->
                  var == key
                end
              )
              |> (&if(!&1,
                    do: {var, nil},
                    else: &1
                  )).()

            [match | acc]

          _, acc ->
            acc
        end)
        |> Enum.into(%{})
      end
    end
  end

  @doc false
  def extract(source, entry, strict?, context) do
    [strict: strict?] = strict?

    Enum.reduce(apply(context, source, []), [], fn
      x, acc ->
        case x do
          {field, identifier, category, {type_constraint, value_constraint}} ->
            {_, val} = find_by_field(entry, field)

            check_correct_type!(type_constraint, val)

            {regex_length, value_length} = lengths(value_constraint, val)
            unequal_lengths? = regex_length != value_length

            if strict? do
              check_correct_value!(value_constraint, val, unequal_lengths?, field, source)
              [{identifier, val} | acc]
            else
              # Emits warning
              check_correct_value(value_constraint, val, unequal_lengths?, field, source)
              [{identifier, val} | acc]
            end

          {field, identifier, category} ->
            {_, val} = find_by_field(entry, field)

            [{identifier, val} | acc]

          _ ->
            acc
        end

      _, acc ->
        acc
    end)
    |> Enum.into(%{})
  end

  defp find_by_field(entry, field) do
    Enum.find(
      entry,
      fn
        {entry_field, _} when is_atom(entry_field) ->
          String.to_atom(field) == entry_field

        {entry_field, _} when is_bitstring(entry_field) ->
          field == entry_field
      end
    )
  end

  defp check_correct_type!(type, value) do
    if is_bitstring(value) and type != :string do
      raise Supercargo.TypeConstraintError, {type, value}
    end
  end

  defp check_correct_value!(regex, value, unequal_lengths?, field, source) do
    if unequal_lengths? do
      raise Supercargo.ValueConstraintError,
            {value, Regex.source(%Regex{source: regex}), field, source}
    else
      :ok
    end
  end

  defp check_correct_value(regex, value, unequal_lengths?, field, source) do
    if unequal_lengths? do
      Logger.warn(
        "Supercargo - (#{source}:#{field}) one or more characters of `#{value}` do not match the regular expression #{Regex.source(regex)}."
      )
    else
      :warning
    end
  end

  defp lengths(regex, value) do
    result = Regex.run(regex, value)

    case result do
      nil ->
        {0, String.length(value)}

      _ ->
        {result |> Enum.at(0) |> String.length(), String.length(value)}
    end
  end
end
