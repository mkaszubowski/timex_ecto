defmodule Timex.EctoOne.DateTimeWithTimezone do
  @moduledoc """
  This is a special type for storing datetime + timezone information as a composite type.

  To use this, you must first make sure you have the `datetimetz` type defined in your database:

  ```sql
  CREATE TYPE datetimetz AS (
      dt timestamptz,
      tz varchar
  );
  ```

  Then you can use that type when creating your table, i.e.:

  ```sql
  CREATE TABLE example (
    id integer,
    created_at datetimetz
  );
  ```

  That's it!
  """
  use Timex

  @behaviour EctoOne.Type

  def type, do: :datetimetz

  @doc """
  We can let EctoOne handle blank input
  """
  defdelegate blank?(value), to: EctoOne.Type

  @doc """
  Handle casting to Timex.EctoOne.DateTimeWithTimezone
  """
  def cast(%DateTime{timezone: nil} = datetime), do: {:ok, %{datetime | :timezone => %TimezoneInfo{}}}
  def cast(%DateTime{} = datetime), do: {:ok, datetime}
  # Support embeds_one/embeds_many
  def cast(%{"calendar" => _,
             "year" => y, "month" => m, "day" => d,
             "hour" => h, "minute" => mm, "second" => s, "ms" => ms,
             "timezone" => %{"full_name" => tz_abbr}}) do
    datetime = Date.from({{y,m,d},{h,mm,s}}, tz_abbr)
    {:ok, %{datetime | :ms => ms}}
  end
  def cast(input) do
    case EctoOne.DateTimeWithTimezone.cast(input) do
      {:ok, datetime} ->
        load({{{datetime.year, datetime.month, datetime.day},
               {datetime.hour, datetime.min, datetime.sec, datetime.usec}
              },
              datetime.timezone
            })
      :error -> :error
    end
  end

  @doc """
  Load from the native EctoOne representation
  """
  def load({ {{year, month, day}, {hour, min, sec, usec}}, timezone}) do
    datetime = Date.from({{year, month, day}, {hour, min, sec}})
    datetime = %{datetime | :ms => Time.from(usec, :usecs) |> Time.to_msecs}
    tz       = Timezone.get(timezone, datetime)
    {:ok, %{datetime | :timezone => tz}}
  end
  def load(_), do: :error

  @doc """
  Convert to the native EctoOne representation
  """
  def dump(%DateTime{timezone: nil} = datetime) do
    {date, {hour, min, second}} = DateConvert.to_erlang_datetime(datetime)
    micros = datetime.ms * 1_000
    {:ok, {{date, {hour, min, second, micros}}, "UTC"}}
  end
  def dump(%DateTime{timezone: %TimezoneInfo{full_name: name}} = datetime) do
    {date, {hour, min, second}} = DateConvert.to_erlang_datetime(datetime)
    micros = datetime.ms * 1_000
    {:ok, {{date, {hour, min, second, micros}}, name}}
  end
  def dump(_), do: :error
end

