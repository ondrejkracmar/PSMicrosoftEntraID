using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using PSMicrosoftEntraID.Http;
using PSMicrosoftEntraID.Resources;
using PSMicrosoftEntraID.Serialization;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Sends Graph $batch envelopes over one shared <see cref="HttpClient"/>.
    /// One client for the whole process keeps the connections (TLS sessions, HTTP/2) open between envelopes - a new
    /// client per call, as Invoke-RestMethod does, pays a TCP and TLS handshake for every envelope. The calls are
    /// asynchronous, so the batch engine keeps several envelopes in flight from a single PowerShell thread without
    /// runspaces, and the answer is read as text and parsed in C# (<see cref="GraphBatchReader"/>), never as
    /// PowerShell objects - with an element type, straight into typed objects (<see cref="GraphJson"/>).
    /// Every envelope carries the module's request timeout and the caller's cancellation: Ctrl+C or a stopped
    /// pipeline ends the envelopes in flight instead of leaving them running in the background.
    /// An envelope goes only over https and only to the scheme, host and port of the service URL it was authorized
    /// for; any other is refused before a connection is opened (<see cref="CheckUri"/>). The check does not depend on
    /// any guard of the module: the client holds it on its own.
    /// </summary>
    public static class GraphBatchClient
    {
        // The test hook: loopback hosts (127.0.0.1, localhost) that may be reached over plain http - the local HTTP
        // servers of the Pester suite. Private and empty in every session: no public member, parameter or setting
        // turns http on; only the test suite fills it, through reflection. A host that is not a loopback address is
        // refused over http even when it is listed.
        private static readonly ConcurrentDictionary<string, bool> HttpTestHosts = new ConcurrentDictionary<string, bool>(StringComparer.OrdinalIgnoreCase);

        private static readonly string UserAgent = string.Format(CultureInfo.InvariantCulture, "PSMicrosoftEntraID/{0}", typeof(GraphBatchClient).Assembly.GetName().Version);

        private static int inFlight;

        /// <summary>
        /// Gets or sets the transport. One pooled client for the process; the unit tests swap in an in-process fake
        /// handler so no test reaches the network.
        /// </summary>
        internal static HttpMessageInvoker Client { get; set; } = new HttpClient(new SocketsHttpHandler
        {
            PooledConnectionLifetime = TimeSpan.FromMinutes(5),
            MaxConnectionsPerServer = 64,
            AutomaticDecompression = DecompressionMethods.All,
        })
        {
            // Each envelope carries its own timeout and cancellation.
            Timeout = Timeout.InfiniteTimeSpan,
        };

        /// <summary>The number of envelopes sent and not yet finished, in the whole process.</summary>
        public static int InFlight => Volatile.Read(ref inFlight);

        /// <summary>
        /// Checks a URL against the service URL it may be sent to: it must be an absolute https URL without user
        /// information, with the scheme, host and port of <paramref name="authorizedUrl"/>. Used for the envelope and
        /// by the engine for every @odata.nextLink before it is followed.
        /// </summary>
        /// <param name="uri">The URL to check.</param>
        /// <param name="authorizedUrl">The service URL (e.g. https://graph.microsoft.com/v1.0).</param>
        /// <returns>Null when the URL may be used; otherwise why not, naming the URL by scheme, host, port and path
        /// only - never its query (skip and delta tokens) or user information.</returns>
        public static string CheckUri(string uri, string authorizedUrl)
        {
            // PowerShell passes $null for a string argument as an empty string.
            if (string.IsNullOrWhiteSpace(authorizedUrl))
            {
                return Strings.BatchNoServiceUrl;
            }

            if (!Uri.TryCreate(uri, UriKind.Absolute, out var target) || !string.IsNullOrEmpty(target.UserInfo) || string.IsNullOrEmpty(target.Host))
            {
                return Strings.BatchInvalidUrl;
            }

            if (!IsAllowedScheme(target))
            {
                return string.Format(CultureInfo.InvariantCulture, Strings.BatchNotHttps, SafeUrl(target));
            }

            if (!Uri.TryCreate(authorizedUrl.Trim(), UriKind.Absolute, out var service) || !IsAllowedScheme(service) || !SameOrigin(target, service))
            {
                return string.Format(CultureInfo.InvariantCulture, Strings.BatchForeignHost, SafeUrl(target), service is null ? string.Empty : service.GetComponents(UriComponents.SchemeAndServer, UriFormat.UriEscaped));
            }

            return null;
        }

        /// <summary>
        /// Posts one envelope and returns its sub-responses, without converting the bodies.
        /// See <see cref="SendAsync(string, IDictionary, string, string[], int, string, Type, CancellationToken)"/>.
        /// </summary>
        /// <param name="uri">The $batch URL.</param>
        /// <param name="headers">Request headers, including Authorization.</param>
        /// <param name="body">The envelope as JSON.</param>
        /// <param name="ids">The ids of the sub-requests in the envelope.</param>
        /// <param name="timeoutSeconds">How long the envelope may take, answer included, in seconds; 0 waits without limit.</param>
        /// <param name="authorizedUrl">The service URL the envelope may go to.</param>
        /// <param name="cancellationToken">Cancels the envelope.</param>
        /// <returns>The sub-responses.</returns>
        public static Task<BatchSubResponse[]> SendAsync(string uri, IDictionary headers, string body, string[] ids, int timeoutSeconds, string authorizedUrl, CancellationToken cancellationToken)
        {
            return SendAsync(uri, headers, body, ids, timeoutSeconds, authorizedUrl, null, cancellationToken);
        }

        /// <summary>
        /// Posts one envelope and returns its sub-responses. The task never fails for an HTTP or network failure, a
        /// timeout or a cancellation: a failed envelope comes back as one synthetic sub-response per request id,
        /// carrying the HTTP status of the envelope and its Retry-After, so the caller retries it like a throttled
        /// sub-request. The synthetic statuses: 421 the envelope was refused before it was sent (not https, another
        /// host, no service URL - not retried), 0 cancelled (the caller has stopped and does not read it), 504 no
        /// answer within the timeout, 502 an answer that is no $batch response, 503 a network failure.
        /// </summary>
        /// <param name="uri">The $batch URL.</param>
        /// <param name="headers">Request headers, including Authorization.</param>
        /// <param name="body">The envelope as JSON.</param>
        /// <param name="ids">The ids of the sub-requests in the envelope.</param>
        /// <param name="timeoutSeconds">How long the envelope may take, answer included, in seconds; 0 waits without limit.</param>
        /// <param name="authorizedUrl">The service URL the envelope may go to: required, its scheme, host and port must
        /// be those of <paramref name="uri"/>, and the scheme https.</param>
        /// <param name="elementType">The type of one item of a page: every successful page is deserialized into
        /// <see cref="BatchSubResponse.Items"/> on the task, straight from its JSON text. Null leaves the bodies as text.</param>
        /// <param name="cancellationToken">Cancels the envelope.</param>
        /// <returns>The sub-responses.</returns>
        public static async Task<BatchSubResponse[]> SendAsync(string uri, IDictionary headers, string body, string[] ids, int timeoutSeconds, string authorizedUrl, Type elementType, CancellationToken cancellationToken)
        {
            ArgumentNullException.ThrowIfNull(ids);

            // Before anything is sent: the access token never goes in clear text or to another host.
            var refusal = CheckUri(uri, authorizedUrl);
            if (refusal is not null)
            {
                return Synthetic(ids, 421, 0, refusal);
            }

            Interlocked.Increment(ref inFlight);
            try
            {
                using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
                RequestTimeout.Apply(timeout, timeoutSeconds);

                try
                {
                    var responses = await SendCoreAsync(uri, headers, body, ids, timeout.Token).ConfigureAwait(false);
                    if (elementType is not null)
                    {
                        ConvertPages(responses, elementType);
                    }

                    return responses;
                }
                catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
                {
                    return Synthetic(ids, 0, 0, Strings.BatchCancelled);
                }
                catch (OperationCanceledException)
                {
                    return Synthetic(ids, 504, 0, RequestTimeout.Describe(timeoutSeconds));
                }
                catch (HttpRequestException exception)
                {
                    return Synthetic(ids, 503, 0, exception.Message);
                }
                catch (IOException exception)
                {
                    // The connection broke while the answer was read.
                    return Synthetic(ids, 503, 0, exception.Message);
                }
                catch (System.Net.Sockets.SocketException exception)
                {
                    // Not always wrapped in an HttpRequestException.
                    return Synthetic(ids, 503, 0, exception.Message);
                }
            }
            finally
            {
                Interlocked.Decrement(ref inFlight);
            }
        }

        private static async Task<BatchSubResponse[]> SendCoreAsync(string uri, IDictionary headers, string body, string[] ids, CancellationToken cancellationToken)
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, uri)
            {
                Content = new StringContent(body ?? string.Empty, Encoding.UTF8, "application/json"),
            };

            // Over TLS (Graph) HTTP/2 is negotiated in the handshake at no extra cost; over plain HTTP (the local test
            // servers) asking for it only adds a fallback round.
            if (request.RequestUri is { Scheme: "https" })
            {
                request.Version = HttpVersion.Version20;
                request.VersionPolicy = HttpVersionPolicy.RequestVersionOrLower;
            }

            if (headers is not null)
            {
                foreach (DictionaryEntry header in headers)
                {
                    var name = System.Convert.ToString(header.Key, CultureInfo.InvariantCulture);
                    if (string.IsNullOrEmpty(name) || string.Equals(name, "Content-Type", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    request.Headers.TryAddWithoutValidation(name, System.Convert.ToString(header.Value, CultureInfo.InvariantCulture));
                }
            }

            if (!request.Headers.Contains("User-Agent"))
            {
                request.Headers.TryAddWithoutValidation("User-Agent", UserAgent);
            }

            using var response = await Client.SendAsync(request, cancellationToken).ConfigureAwait(false);
            var text = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            if (response.IsSuccessStatusCode)
            {
                try
                {
                    return GraphBatchReader.Parse(text);
                }
                catch (Exception exception) when (exception is ArgumentException or JsonException or InvalidOperationException)
                {
                    // An answer that is no $batch response (a proxy page, a cut-off body) is a bad gateway: retried like an
                    // unavailable envelope. The parser's own message is never passed on - System.Text.Json quotes the
                    // invalid run of the body in it, which can be a session id or a token.
                    return Synthetic(ids, 502, 0, DescribeInvalidAnswer(exception));
                }
            }

            var retryAfter = 0;
            if (response.Headers.RetryAfter?.Delta is { } delta)
            {
                retryAfter = RetryAfter.Limit(delta.TotalSeconds);
            }
            else if (response.Headers.RetryAfter?.Date is { } date)
            {
                retryAfter = RetryAfter.Limit((date - DateTimeOffset.UtcNow).TotalSeconds);
            }

            return Synthetic(ids, (int)response.StatusCode, retryAfter, string.IsNullOrWhiteSpace(text) ? response.ReasonPhrase : text);
        }

        private static void ConvertPages(BatchSubResponse[] responses, Type elementType)
        {
            foreach (var response in responses)
            {
                if (!response.IsSuccess || string.IsNullOrWhiteSpace(response.Body))
                {
                    continue;
                }

                try
                {
                    response.Items = GraphJson.DeserializeCollection(response.Body, elementType);
                }
                catch (JsonException exception)
                {
                    // The type and the JSON path only: the message of System.Text.Json may quote the body.
                    response.ConversionError = string.Format(CultureInfo.InvariantCulture, Strings.ConversionFailed, elementType.FullName, exception.GetType().Name, exception.Path ?? "$");
                }
                catch (NotSupportedException exception)
                {
                    response.ConversionError = string.Format(CultureInfo.InvariantCulture, Strings.ConversionFailed, elementType.FullName, exception.GetType().Name, "$");
                }
            }
        }

        private static string DescribeInvalidAnswer(Exception exception)
        {
            if (exception is JsonException { LineNumber: { } line, BytePositionInLine: { } position })
            {
                return string.Format(CultureInfo.InvariantCulture, Strings.BatchInvalidAnswerAt, exception.GetType().Name, line + 1, position + 1);
            }

            return string.Format(CultureInfo.InvariantCulture, Strings.BatchInvalidAnswer, exception.GetType().Name);
        }

        private static bool IsAllowedScheme(Uri uri) =>
            uri.Scheme == Uri.UriSchemeHttps
            || (uri.Scheme == Uri.UriSchemeHttp && uri.IsLoopback && HttpTestHosts.ContainsKey(uri.IdnHost));

        private static bool SameOrigin(Uri target, Uri service) =>
            string.Equals(target.Scheme, service.Scheme, StringComparison.OrdinalIgnoreCase)
            && string.Equals(target.IdnHost, service.IdnHost, StringComparison.OrdinalIgnoreCase)
            && target.Port == service.Port;

        // Scheme, host, port and path: no user information, no query (delta and skip tokens), no fragment.
        private static string SafeUrl(Uri uri) => uri.GetComponents(UriComponents.SchemeAndServer | UriComponents.Path, UriFormat.UriEscaped);

        private static BatchSubResponse[] Synthetic(string[] ids, int status, int retryAfter, string message)
        {
            var result = new BatchSubResponse[ids.Length];
            for (var index = 0; index < ids.Length; index++)
            {
                result[index] = new BatchSubResponse { Id = ids[index], Status = status, RetryAfter = retryAfter, ErrorMessage = message };
            }

            return result;
        }
    }
}
