defmodule SupercargoTest do
  use ExUnit.Case
  import Assertions, only: [assert_maps_equal: 3, assert_lists_equal: 3]
  alias TestHelper.Manifest, as: Manifest
  alias TestHelper.API, as: API

  describe "uncategorized variable," do
    test "accessors" do
      csv_fn = fn
        {:ok, entry} ->
          e = Manifest.extract(:csv, entry)
          Manifest.id(e)
        _ ->
          %{}
      end

      [csv_results] = get_data_from_csv(csv_fn, "priv/static/data_with_uncategorized.csv") |> Enum.take(1)

      assert csv_results == %{id: "1"}
    end
  end

  describe "extract/1," do
    test "" do
      result =
        Manifest.extract(:csv)
        |> Enum.each(fn e ->
          Manifest.meta(e)
        end)

      assert result == :ok
    end
  end

  describe "extract/2, interleaved," do
    test "extraction from different schemas are equal" do
      api_fn = fn
        entry ->
          Manifest.extract(:api, entry)
        _ ->
          %{}
      end

      csv_fn = fn
        {:ok, entry} ->
          Manifest.extract(:csv, entry)

        _ ->
          %{}
      end

      api_results = get_data_from_api(api_fn) |> Enum.take(5)
      csv_results = get_data_from_csv(csv_fn) |> Enum.take(5)

      assert_lists_equal(
        api_results,
        csv_results,
        &assert_maps_equal(&1, &2, [:index, :name, :url])
      )
    end

    test "+ category accessor" do
      api_fn = fn
        entry ->
          e = Manifest.extract(:api, entry)
          Manifest.meta(e)
          Manifest.name(e)

        _ ->
          %{}
      end

      csv_fn = fn
        {:ok, entry} ->
          e = Manifest.extract(:csv, entry)
          Manifest.meta(e)
          Manifest.name(e)

        _ ->
          %{}
      end

      api_results = get_data_from_api(api_fn) |> Enum.take(5)
      csv_results = get_data_from_csv(csv_fn) |> Enum.take(5)

      assert_lists_equal(
        api_results,
        csv_results,
        &assert_maps_equal(&1, &2, [:index, :name, :url])
      )
    end
  end

  describe "extract/2, post," do
    test "extraction from different schemas are equal" do
      api_fn = fn entry -> entry end

      csv_fn = fn
        {:ok, entry} ->
          entry

        _ ->
          %{}
      end

      api_results = Manifest.extract(:api, get_data_from_api(api_fn)) |> Enum.take(5)
      csv_results = Manifest.extract(:csv, get_data_from_csv(csv_fn)) |> Enum.take(5)

      assert_lists_equal(
        api_results,
        csv_results,
        &assert_maps_equal(&1, &2, [:index, :name, :url])
      )
    end

    test "+ category accessor" do
      api_fn = fn entry -> entry end

      csv_fn = fn
        {:ok, entry} ->
          entry

        _ ->
          %{}
      end

      api_results =
        Manifest.extract(:api, get_data_from_api(api_fn))
        |> Enum.map(fn e ->
          Manifest.meta(e)
        end)
        |> Enum.take(5)

      csv_results =
        Manifest.extract(:csv, get_data_from_csv(csv_fn))
        |> Enum.map(fn e ->
          Manifest.meta(e)
        end)
        |> Enum.take(5)

      assert_lists_equal(
        api_results,
        csv_results,
        &assert_maps_equal(&1, &2, [:index, :name, :url])
      )
    end
  end

  defp get_data_from_api(fun) do
    API.start()

    API.get!("/classes").body["results"]
    |> Stream.map(fun)
    |> Enum.to_list()
  end

  defp get_data_from_csv(fun, file \\ "priv/static/data.csv") do
    file
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Stream.map(fun)
    |> Enum.to_list()
  end
end
