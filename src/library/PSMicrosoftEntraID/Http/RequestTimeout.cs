using System;
using System.Globalization;
using System.Threading;

namespace PSMicrosoftEntraID.Http
{
    /// <summary>
    /// The module's request timeout (Settings.Request.TimeoutSeconds), applied to $batch envelopes
    /// (<see cref="Batch.GraphBatchClient"/>).
    /// </summary>
    public static class RequestTimeout
    {
        /// <summary>
        /// The longest timeout in whole seconds: a <see cref="CancellationTokenSource"/> accepts at most
        /// <see cref="uint.MaxValue"/> - 1 milliseconds (about 49.7 days). A longer value is applied as this one.
        /// </summary>
        public const int MaxSeconds = 4_294_967;

        /// <summary>
        /// Arms <paramref name="source"/> to cancel after <paramref name="seconds"/>; 0 or less sets no limit.
        /// </summary>
        /// <param name="source">The source that cancels the request.</param>
        /// <param name="seconds">The timeout in seconds.</param>
        public static void Apply(CancellationTokenSource source, int seconds)
        {
            ArgumentNullException.ThrowIfNull(source);
            if (seconds > 0)
            {
                source.CancelAfter(TimeSpan.FromSeconds(Math.Min(seconds, MaxSeconds)));
            }
        }

        /// <summary>
        /// The text of a timeout, without a closing full stop - callers embed it in sentences of their own.
        /// </summary>
        /// <param name="seconds">The timeout in seconds.</param>
        /// <returns>For example "No answer within 1 second" or "No answer within 600 seconds".</returns>
        public static string Describe(int seconds)
        {
            var applied = Math.Min(seconds, MaxSeconds);
            return applied == 1
                ? "No answer within 1 second"
                : string.Format(CultureInfo.InvariantCulture, "No answer within {0} seconds", applied);
        }
    }
}
