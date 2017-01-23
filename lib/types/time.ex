defmodule Timex.EctoOne.Time do
  @moduledoc """
  Support for using Timex with :time fields
  """
  use Timex
  alias EctoOne.Time

  @behaviour EctoOne.Type

  def type, do: :time

  @doc """
  We can let EctoOne handle blank input
  """
  defdelegate blank?(value), to: EctoOne.Type

  @doc """
  Handle casting to Timex.EctoOne.Time
  """
  def cast(input) when is_binary(input) do
    case DateFormat.parse(input, "{ISOtime}") do
      {:ok, datetime} ->
        datetime = %{datetime | :timezone => %TimezoneInfo{}}
        {:ok, Date.to_secs(datetime) |> Time.add(Time.epoch)}
      {:error, _}     -> :error
    end
  end
  def cast({_, _, _} = timestamp), do: {:ok, timestamp}
  # Support embeds_one/embeds_many
  def cast(%{"calendar" => _,
             "year" => _, "month" => _, "day" => _,
             "hour" => h, "minute" => mm, "second" => s, "ms" => ms,
             "timezone" => _}) do
    load({h, mm, s, ms * 1_000})
  end
  def cast(input) do
    case EctoOne.Time.cast(input) do
      {:ok, time} -> load({time.hour, time.minute, time.second, time.usecs})
      :error -> :error
    end
  end

  @doc """
  Load from the native EctoOne representation
  """
  def load({hour, minute, second, usecs}) do
    time = %{Date.epoch | :hour => hour, :minute => minute, :second => second, :ms => usecs / 1_000} |> Date.to_timestamp(:epoch)
    {:ok, time}
  end
  def load(_), do: :error

  @doc """
  Convert to the native EctoOne representation
  """
  def dump({_mega, _sec, _micro} = timestamp) do
    %DateTime{hour: h, minute: m, second: s, ms: ms} = Date.from(timestamp, :timestamp, :epoch)
    {:ok, {h, m, s, ms * 1_000}}
  end
  def dump(_), do: :error
end

