defmodule Supercargo.Internal do
  import Supercargo.Utils

  def generate_source_ast(%{source: source, values: values}) do
    quote do
      def unquote(construct_atomized_name(["internal__", source]))() do
        unquote(Macro.escape(values))
      end
    end
  end


  def generate_uncategorized_variable_ast(%{kv: kv, identifier: identifier}) do
    quote do
      def unquote(construct_atomized_name(["internal__", identifier]))() do
        %{unquote(kv)}
      end
    end
  end

  def generate_category_ast(%{source: source, category: category, values: values}) do
    quote do
      def unquote(construct_atomized_name(["internal__", source, "__", category]))() do
        unquote(Macro.escape(values))
      end
    end
  end
end
