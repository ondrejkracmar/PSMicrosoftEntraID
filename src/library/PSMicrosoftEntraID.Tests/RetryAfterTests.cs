using System.Globalization;
using PSMicrosoftEntraID.Batch;
using Xunit;

namespace PSMicrosoftEntraID.Tests;

/// <summary>
/// Retry-After as delay-seconds or an HTTP-date, as whole seconds between 0 and 5 minutes.
/// </summary>
public class RetryAfterTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 31, 12, 0, 0, TimeSpan.Zero);

    [Theory]
    [InlineData("120", 120)]
    [InlineData(" 7 ", 7)]
    [InlineData("0", 0)]
    [InlineData("-5", 0)]
    [InlineData("300", 300)]
    [InlineData("1000", 300)]
    [InlineData("99999999999999", 300)]
    public void ReadsDelaySeconds(string value, int expected)
    {
        Assert.Equal(expected, RetryAfter.ParseSeconds(value, Now));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("soon")]
    public void ReadsNothingAsNoWait(string value)
    {
        Assert.Equal(0, RetryAfter.ParseSeconds(value, Now));
    }

    [Theory]
    [InlineData(30, 30)]
    [InlineData(-30, 0)]
    [InlineData(3600, 300)]
    public void ReadsAnHttpDate(int offsetSeconds, int expected)
    {
        string date = Now.AddSeconds(offsetSeconds).ToString("r", CultureInfo.InvariantCulture);
        Assert.Equal(expected, RetryAfter.ParseSeconds(date, Now));
    }

    [Theory]
    [InlineData(0.2, 1)]
    [InlineData(1.0, 1)]
    [InlineData(299.1, 300)]
    [InlineData(0.0, 0)]
    [InlineData(double.NaN, 0)]
    public void LimitsAndRoundsUp(double seconds, int expected)
    {
        Assert.Equal(expected, RetryAfter.Limit(seconds));
    }
}
