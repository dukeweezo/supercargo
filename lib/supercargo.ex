defmodule Supercargo do
  @moduledoc """
  Disclaimer: Supercargo is currently under heavy development, so design and usage may change drastically.

  See https://github.com/dukeweezo/supercargo for current usage.
  """
  import Supercargo.Utils

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
    [maplines] =
      Module.get_attribute(env.module, :maplines)
      |> (&if(length(&1) > 0,
            do: &1,
            else:
              raise(
                Supercargo.UsageError,
                "A mapline must be defined in valid format in the manifest."
              )
          )).()

    [extraction] =
      Module.get_attribute(env.module, :extraction)
      |> (&if(length(&1) > 0,
            do: &1,
            else: [{}]
          )).()

    compile(maplines, extraction)
  end

  defmacro extract(entries, source) do
    quote bind_quoted: [entries: entries, source: source] do
      @extraction {entries, source}
    end
  end

  defmacro register_mapline(sources, structure) do
    quote bind_quoted: [sources: sources, structure: structure] do
      @maplines {sources, structure}
    end
  end

  defp compile({sources, structure}, extraction) do
    Validator.validate!(sources, structure)
    vast = Parser.parse(sources, structure)

    accessors_ast =
      for token <- vast do
        Generator.run(token, sources)
      end

    compiled_extract_ast =
      if tuple_size(extraction) > 0 do
        {entries, source} = extraction

        for source <- sources do
          generate_compiled_extract_ast(entries, source)
        end
      end

    runtime_extract_ast =
      for source <- sources do
        generate_runtime_extract_ast(source)
      end

    [compiled_extract_ast, runtime_extract_ast, accessors_ast]
  end

  defp generate_compiled_extract_ast(entries, source) do
    entries = Macro.escape(entries)

    quote do
      def extract(unquote(source)) do
        Supercargo.extract(unquote(source), unquote(entries), [strict: false], __MODULE__)
      end

      def extract!(unquote(source)) do
        Supercargo.extract(unquote(source), unquote(entries), [strict: true], __MODULE__)
      end
    end
  end

  defp generate_runtime_extract_ast(source) do
    quote do
      def extract(unquote(source), entry_or_entries) do
        Supercargo.extract(unquote(source), entry_or_entries, [strict: false], __MODULE__)
      end

      def extract!(unquote(source), entry_or_entries) do
        Supercargo.extract(unquote(source), entry_or_entries, [strict: true], __MODULE__)
      end
    end
  end

  def generate_uncategorized_variable_ast(%{source: source, kv: kv, identifier: identifier}) do
    quote do
      def unquote(identifier)(ext) do     
        data = __MODULE__.unquote(construct_atomized_name(["internal__", identifier]))()
        [{field, var}] = Map.to_list(data)

        [Supercargo.match_fields(var, ext)] 
        |> Enum.into(%{})
      end
    end
  end

  @doc false
  def generate_category_ast(%{source: source, category: category}) do
    quote do
      def unquote(category)(ext) do
        data = __MODULE__.unquote(construct_atomized_name(["internal__", source, "__", category]))()

        Enum.reduce(data, [], fn
          {field, var}, acc ->          
            [Supercargo.match_fields(var, ext) | acc]
          _, acc ->
            acc
        end)
        |> Enum.into(%{})
      end
    end
  end

  @doc false
  def match_fields(var, ext) do
    Enum.find(ext,
      fn {key, _} ->
        var == key
    end)
    |> (&if(!&1,
         do: {var, nil},
         else: &1
       )).()
  end

  @doc false
  def extract(source, entries = [_ | _], strict?, context) do
    [strict: strict?] = strict?

    Enum.map(
      entries,
      fn entry ->
        extract_entry(source, entry, strict?, context)
      end
    )
  end

  @doc false
  def extract(source, entry = %{}, strict?, context) do
    [strict: strict?] = strict?

    extract_entry(source, entry, strict?, context)
  end

  defp extract_entry(source, entry, strict?, context) do
    Enum.reduce(apply(context, construct_atomized_name(["internal__", source]), []), [], fn
      x, acc ->
        case x do
          {field, identifier} ->
            res =
              case find_by_field(entry, field) do
                {_, val} ->
                  [{identifier, val} | acc]

                nil ->
                  acc
              end

            res

          {field, identifier, _category, {type_constraint, value_constraint}} ->
            find_by_field(entry, field)

            val =
              case find_by_field(entry, field) do
                {_, val} ->
                  val

                nil ->
                  raise Supercargo.ExtractError,
                        "Can't find a field corresponding to a field in `#{source}`. The mapline may not match the entry / entries."
              end

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

          {field, identifier, _category} ->
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

  defp find_by_field(entries, field) do
    Enum.find(entries, fn
      {entries_field, _} when is_atom(entries_field) ->
        String.to_atom(field) == entries_field

      {entries_field, _} when is_bitstring(entries_field) ->
        field == entries_field
    end)
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
