defmodule SupercargoTest do
  use ExUnit.Case
  import Assertions, only: [assert_maps_equal: 3, assert_lists_equal: 3]
  alias TestHelper.Manifest, as: Manifest
  alias TestHelper.API, as: API

  describe "extract/2," do
    test "extraction from different schemas are equal" do
      API.start()

      api_results =
        API.get!("/classes").body["results"]
        |> Stream.map(fn
          entry ->
            e = Manifest.extract(:api, entry)
            Manifest.meta(e)

          _ ->
            %{}
        end)
        |> Enum.to_list()
        |> Enum.take(5)

      csv_results =
        "priv/static/data.csv"
        |> Path.expand(__DIR__)
        |> File.stream!()
        |> CSV.decode(headers: true)
        |> Stream.map(fn
          {:ok, entry} ->
            e = Manifest.extract(:csv, entry)
            Manifest.meta(e)

          _ ->
            %{}
        end)
        |> Enum.to_list()
        |> Enum.take(5)

      assert_lists_equal(
        api_results,
        csv_results,
        &assert_maps_equal(&1, &2, [:index, :name, :url])
      )
    end
  end
end
