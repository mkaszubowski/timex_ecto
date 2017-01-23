defmodule Timex.EctoOne.Date do
  @moduledoc """
  Support for using Timex with :date fields
  """
  use Timex

  @behaviour EctoOne.Type

  def type, do: :date

  @doc """
  We can let EctoOne handle blank input
  """
  defdelegate blank?(value), to: EctoOne.Type

  @doc """
  Handle casting to Timex.EctoOne.Date
  """
  def cast(%DateTime{timezone: nil} = datetime), do: {:ok, %{datetime | :timezone => %TimezoneInfo{}}}
  def cast(%DateTime{} = datetime),              do: {:ok, datetime}
  # Support embeds_one/embeds_many
  def cast(%{"calendar" => _,
             "year" => y, "month" => m, "day" => d,
             "hour" => _, "minute" => _, "second" => _, "ms" => _,
             "timezone" => %{"full_name" => tz_abbr}}) do
    date = Date.from({y,m,d}, tz_abbr)
    {:ok, date}
  end
  def cast(input) do
    case EctoOne.Date.cast(input) do
      {:ok, date} -> load({date.year, date.month, date.day})
      :error -> :error
    end
  end

  @doc """
  Load from the native EctoOne representation
  """
  def load({_year, _month, _day} = date), do: {:ok, Date.from(date)}
  def load(_), do: :error

  @doc """
  Convert to native EctoOne representation
  """
  def dump(%DateTime{} = datetime) do
    {{year, month, day}, _} = datetime |> Timezone.convert("UTC") |> DateConvert.to_erlang_datetime
    {:ok, {year, month, day}}
  end
  def dump(_), do: :error
end

