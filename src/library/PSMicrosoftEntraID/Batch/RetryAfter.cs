using System;
using System.Globalization;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Reads the Retry-After of a throttled or unavailable answer: delay-seconds or an HTTP-date (RFC 9110 10.2.3),
    /// as a wait in whole seconds of at most <see cref="MaximumSeconds"/> - a service that asks for more is waited for
    /// five minutes.
    /// </summary>
    public static class RetryAfter
    {
        /// <summary>The longest wait in seconds: 5 minutes.</summary>
        public const int MaximumSeconds = 300;

        /// <summary>
        /// The wait <paramref name="value"/> asks for, from now: 0 when it is empty, unreadable or in the past.
        /// </summary>
        /// <param name="value">The header value.</param>
        /// <returns>The wait in whole seconds.</returns>
        public static int ParseSeconds(string value) => ParseSeconds(value, DateTimeOffset.UtcNow);

        /// <summary>
        /// The wait <paramref name="value"/> asks for, from <paramref name="now"/>: 0 when it is empty, unreadable or in
        /// the past, at most <see cref="MaximumSeconds"/>.
        /// </summary>
        /// <param name="value">The header value.</param>
        /// <param name="now">The time an HTTP-date is counted from.</param>
        /// <returns>The wait in whole seconds.</returns>
        public static int ParseSeconds(string value, DateTimeOffset now)
        {
            if (string.IsNullOrWhiteSpace(value)) return 0;
            var text = value.Trim();
            if (long.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out var seconds)) return Limit(seconds);
            if (DateTimeOffset.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var date))
            {
                return Limit((date - now).TotalSeconds);
            }
            return 0;
        }

        /// <summary>A wait in seconds rounded up to whole seconds, between 0 and <see cref="MaximumSeconds"/>.</summary>
        /// <param name="seconds">The wait asked for.</param>
        /// <returns>The wait in whole seconds.</returns>
        public static int Limit(double seconds)
        {
            if (double.IsNaN(seconds) || seconds <= 0) return 0;
            if (seconds >= MaximumSeconds) return MaximumSeconds;
            return (int)Math.Ceiling(seconds);
        }
    }
}
