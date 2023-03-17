ExUnit.start()

defmodule TestHelper.API do
  use HTTPoison.Base

  def process_request_url(url) do
    "https://www.dnd5eapi.co/api/" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!()
  end
end

defmodule TestHelper.Manifest do
  use Supercargo

  @index {["index", "Field1"], [:_index, :string, ~r/[a-zA-Z]+/]}
  @name {["name", "Field2"], [:name, :string, ~r/[a-zA-Z]+/]}
  @url {["url", "Field3"], [:_url, :string, ~r/[a-zA-Z\/]+/]}

  register_mapline(
    [:api, :csv],
    %{
      "uncategorized" => :id,
      :name => %{
        elem(@name, 0) => elem(@name, 1)
      },
      :meta => %{
        elem(@index, 0) => elem(@index, 1),
        elem(@url, 0) => elem(@url, 1)
      }
    }
  )

  # Compiled data example
  csv =
    "priv/static/data.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Stream.map(fn
      {:ok, entry} ->
        entry

      _ ->
        %{}
    end)
    |> Enum.to_list()

  extract(csv, :csv)
end

# defmodule TestHelper.BrokenManifest do use Supercargo end

defmodule TestHelper.ManifestWithoutExtract do
  use Supercargo

  @index {["index", "Field1"], [:_index, :string, ~r/[a-zA-Z]+/]}
  @name {["name", "Field2"], [:name, :string, ~r/[a-zA-Z]+/]}
  @url {["url", "Field3"], [:_url, :string, ~r/[a-zA-Z\/]+/]}

  register_mapline(
    [:api, :csv],
    %{
      :name => %{
        elem(@name, 0) => elem(@name, 1)
      },
      :meta => %{
        elem(@index, 0) => elem(@index, 1),
        elem(@url, 0) => elem(@url, 1)
      }
    }
  )
end
