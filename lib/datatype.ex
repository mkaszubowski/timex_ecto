defimpl EctoOne.DataType, for: Timex.DateTime do
  use Timex

  def cast(%DateTime{} = datetime, type) when type in [:date, Timex.EctoOne.Date] do
    Timex.EctoOne.Date.dump(datetime)
  end
  def cast(%DateTime{} = datetime, type) when type in [:datetime, Timex.EctoOne.DateTime] do
    Timex.EctoOne.DateTime.dump(datetime)
  end
  def cast(%DateTime{} = datetime, type) when type in [:time, Timex.EctoOne.Time] do
    datetime
    |> Date.to_timestamp
    |> Timex.EctoOne.Time.dump
  end
  def cast(%DateTime{} = datetime, Timex.EctoOne.DateTimeWithTimezone) do
    Timex.EctoOne.DateTimeWithTimezone.dump(datetime)
  end
  def cast(_, _) do
    :error
  end
end
