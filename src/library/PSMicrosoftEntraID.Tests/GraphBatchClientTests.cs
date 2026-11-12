using System.Collections;
using System.Globalization;
using System.Net;
using System.Text;
using PSMicrosoftEntraID.Batch;
using PSMicrosoftEntraID.Users;
using Xunit;

namespace PSMicrosoftEntraID.Tests;

/// <summary>
/// GraphBatchClient against an in-process fake handler: nothing leaves the process. The client never throws for a
/// failed envelope - every failure comes back as one synthetic sub-response per request id, with the status the
/// engine's retry decision reads (421 refused, 0 cancelled, 504 timeout, 502 unreadable answer, 503 network).
/// The tests of this class swap the process-wide transport, so they all live in this one class (xUnit runs the
/// tests of a class one after the other).
/// </summary>
public class GraphBatchClientTests
{
    private const string Service = "https://graph.microsoft.com/v1.0";
    private const string BatchUri = Service + "/$batch";
    private static readonly string[] Ids = { "1", "2" };

    private sealed class FakeHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> answer;

        public FakeHandler(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> answer) => this.answer = answer;

        public List<HttpRequestMessage> Requests { get; } = new();

        public List<string> Bodies { get; } = new();

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Requests.Add(request);
            Bodies.Add(request.Content is null ? string.Empty : await request.Content.ReadAsStringAsync(cancellationToken));
            return await answer(request, cancellationToken);
        }
    }

    private static HttpResponseMessage Json(HttpStatusCode status, string body) => new(status) { Content = new StringContent(body, Encoding.UTF8, "application/json") };

    private static async Task<(BatchSubResponse[] Responses, FakeHandler Handler)> Send(
        Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> answer,
        string uri = BatchUri,
        string authorizedUrl = Service,
        IDictionary headers = null,
        int timeoutSeconds = 30,
        Type elementType = null,
        CancellationToken cancellationToken = default)
    {
        var handler = new FakeHandler(answer);
        var before = GraphBatchClient.Client;
        GraphBatchClient.Client = new HttpMessageInvoker(handler);
        try
        {
            var responses = await GraphBatchClient.SendAsync(uri, headers ?? new Hashtable { ["Authorization"] = "Bearer test" }, "{\"requests\":[]}", Ids, timeoutSeconds, authorizedUrl, elementType, cancellationToken);
            return (responses, handler);
        }
        finally
        {
            GraphBatchClient.Client = before;
        }
    }

    [Fact]
    public async Task ReadsTheSubResponsesOfAnAnsweredEnvelope()
    {
        var (responses, handler) = await Send((_, _) => Task.FromResult(Json(HttpStatusCode.OK, """{"responses":[{"id":"2","status":404,"body":{"error":{"message":"gone"}}},{"id":"1","status":200,"body":{"value":[{"id":"a"}]}}]}""")));

        Assert.Equal(new[] { 404, 200 }, responses.Select(r => r.Status));
        Assert.Equal("gone", responses[0].ErrorMessage);
        Assert.Equal(1, responses[1].ItemCount);
        var request = Assert.Single(handler.Requests);
        Assert.Equal(HttpMethod.Post, request.Method);
        Assert.Equal(BatchUri, request.RequestUri!.AbsoluteUri);
        Assert.Equal("Bearer test", request.Headers.Authorization!.ToString());
        Assert.StartsWith("PSMicrosoftEntraID/", request.Headers.UserAgent.ToString());
        Assert.Equal("application/json", request.Content!.Headers.ContentType!.MediaType);
        Assert.Equal("{\"requests\":[]}", handler.Bodies[0]);
    }

    [Fact]
    public async Task PassesTheCallersHeadersButNotItsContentType()
    {
        var headers = new Hashtable { ["Authorization"] = "Bearer test", ["ConsistencyLevel"] = "eventual", ["Content-Type"] = "text/plain" };
        var (_, handler) = await Send((_, _) => Task.FromResult(Json(HttpStatusCode.OK, """{"responses":[]}""")), headers: headers);

        var request = Assert.Single(handler.Requests);
        Assert.Equal("eventual", request.Headers.GetValues("ConsistencyLevel").Single());
        Assert.Equal("application/json", request.Content!.Headers.ContentType!.MediaType);
    }

    [Theory]
    [InlineData("http://graph.microsoft.com/v1.0/$batch", Service, "is not an https URL")]
    [InlineData("https://graph.contoso.com/v1.0/$batch", Service, "is not on the host of the service")]
    [InlineData("https://graph.microsoft.com:8443/v1.0/$batch", Service, "is not on the host of the service")]
    [InlineData("https://user:secret@graph.microsoft.com/v1.0/$batch", Service, "not an absolute URL without user information")]
    [InlineData("/v1.0/$batch", Service, "not an absolute URL without user information")]
    [InlineData(BatchUri, null, "no service URL")]
    [InlineData(BatchUri, "", "no service URL")]
    [InlineData(BatchUri, "http://graph.microsoft.com/v1.0", "is not on the host of the service")]
    public async Task RefusesAnEnvelopeToAnotherPlaceWithoutSendingIt(string uri, string authorizedUrl, string reason)
    {
        var (responses, handler) = await Send((_, _) => throw new InvalidOperationException("must not be sent"), uri, authorizedUrl);

        Assert.Empty(handler.Requests);
        Assert.Equal(2, responses.Length);
        Assert.All(responses, r => Assert.Equal(421, r.Status));
        Assert.Equal(Ids, responses.Select(r => r.Id));
        Assert.Contains(reason, responses[0].ErrorMessage);
        Assert.DoesNotContain("secret", responses[0].ErrorMessage);
    }

    [Fact]
    public void ChecksANextLinkAgainstTheServiceWithoutQuotingItsQuery()
    {
        Assert.Null(GraphBatchClient.CheckUri("https://graph.microsoft.com/v1.0/users?$skiptoken=abc", Service));
        Assert.Null(GraphBatchClient.CheckUri("https://GRAPH.microsoft.com/beta/users", Service));
        var refusal = GraphBatchClient.CheckUri("https://evil.contoso.com/v1.0/users?$skiptoken=S3cr3t", Service);
        Assert.Contains("https://evil.contoso.com/v1.0/users", refusal);
        Assert.DoesNotContain("S3cr3t", refusal);
        Assert.NotNull(GraphBatchClient.CheckUri("http://graph.microsoft.com/v1.0/users", Service));
    }

    [Theory]
    [InlineData(HttpStatusCode.TooManyRequests)]
    [InlineData(HttpStatusCode.ServiceUnavailable)]
    public async Task ReturnsAThrottledEnvelopeAsOneSubResponsePerIdWithItsRetryAfter(HttpStatusCode status)
    {
        var (responses, _) = await Send((_, _) =>
        {
            var answer = Json(status, """{"error":{"message":"slow down"}}""");
            answer.Headers.Add("Retry-After", "30");
            return Task.FromResult(answer);
        });

        Assert.All(responses, r => Assert.Equal((int)status, r.Status));
        Assert.All(responses, r => Assert.Equal(30, r.RetryAfter));
        Assert.Equal(Ids, responses.Select(r => r.Id));
    }

    [Fact]
    public async Task ReadsTheRetryAfterOfAThrottledEnvelopeAsAnHttpDateOfAtMostFiveMinutes()
    {
        var (responses, _) = await Send((_, _) =>
        {
            var answer = Json(HttpStatusCode.TooManyRequests, "{}");
            answer.Headers.Add("Retry-After", DateTimeOffset.UtcNow.AddHours(2).ToString("r", CultureInfo.InvariantCulture));
            return Task.FromResult(answer);
        });

        Assert.All(responses, r => Assert.Equal(RetryAfter.MaximumSeconds, r.RetryAfter));
    }

    [Theory]
    [InlineData("<html>Sign in to the proxy, session S3cr3tPr0xy</html>")]
    [InlineData("tokenS3cr3tPr0xy=abc and more")]
    [InlineData("""{"value":[]}""")]
    public async Task ReturnsAnAnswerThatIsNoBatchResponseAs502WithoutQuotingIt(string body)
    {
        var (responses, _) = await Send((_, _) => Task.FromResult(Json(HttpStatusCode.OK, body)));

        Assert.All(responses, r => Assert.Equal(502, r.Status));
        Assert.StartsWith("The answer is not a valid $batch response", responses[0].ErrorMessage);
        Assert.DoesNotContain("S3cr3tPr0xy", responses[0].ErrorMessage);
    }

    [Fact]
    public async Task ReturnsANetworkFailureAs503()
    {
        var (responses, _) = await Send((_, _) => throw new HttpRequestException("No such host is known."));

        Assert.All(responses, r => Assert.Equal(503, r.Status));
        Assert.Equal("No such host is known.", responses[0].ErrorMessage);
    }

    [Fact]
    public async Task ReturnsAnEnvelopeWithoutAnAnswerInTimeAs504()
    {
        var before = GraphBatchClient.InFlight;
        var (responses, _) = await Send(async (_, token) =>
        {
            await Task.Delay(Timeout.Infinite, token);
            return Json(HttpStatusCode.OK, "{}");
        }, timeoutSeconds: 1);

        Assert.All(responses, r => Assert.Equal(504, r.Status));
        Assert.Equal("No answer within 1 second", responses[0].ErrorMessage);
        Assert.Equal(before, GraphBatchClient.InFlight);
    }

    [Fact]
    public async Task ReturnsACancelledEnvelopeAsStatusZeroAndCountsItOut()
    {
        using var cancel = new CancellationTokenSource();
        var before = GraphBatchClient.InFlight;
        var started = new TaskCompletionSource();
        var sending = Send(async (_, token) =>
        {
            started.SetResult();
            await Task.Delay(Timeout.Infinite, token);
            return Json(HttpStatusCode.OK, "{}");
        }, timeoutSeconds: 0, cancellationToken: cancel.Token);

        await started.Task.WaitAsync(TimeSpan.FromSeconds(10));
        Assert.Equal(before + 1, GraphBatchClient.InFlight);
        cancel.Cancel();
        var (responses, _) = await sending.WaitAsync(TimeSpan.FromSeconds(10));

        Assert.All(responses, r => Assert.Equal(0, r.Status));
        Assert.Equal(before, GraphBatchClient.InFlight);
    }

    [Fact]
    public async Task DeserializesEverySuccessfulPageIntoTheElementType()
    {
        const string answer = """
            {"responses":[
              {"id":"1","status":200,"body":{"value":[{"id":"u1","userPrincipalName":"adele@contoso.com","accountEnabled":true},{"id":"u2","userPrincipalName":"alex@contoso.com","accountEnabled":false}]}},
              {"id":"2","status":403,"body":{"error":{"message":"denied"}}}
            ]}
            """;
        var (responses, _) = await Send((_, _) => Task.FromResult(Json(HttpStatusCode.OK, answer)), elementType: typeof(User));

        var users = Assert.IsType<User[]>(responses[0].Items);
        Assert.Equal(new[] { "adele@contoso.com", "alex@contoso.com" }, users.Select(u => u.UserPrincipalName));
        Assert.True(users[0].AccountEnabled);
        Assert.Null(responses[0].ConversionError);
        Assert.Null(responses[1].Items);
        Assert.Equal("denied", responses[1].ErrorMessage);
    }

    [Fact]
    public async Task ReportsAPageThatDoesNotConvertWithoutQuotingIt()
    {
        const string answer = """{"responses":[{"id":"1","status":200,"body":{"value":[{"id":"u1","displayName":{"S3cr3t":"x"}}]}}]}""";
        var (responses, _) = await Send((_, _) => Task.FromResult(Json(HttpStatusCode.OK, answer)), elementType: typeof(User));

        Assert.Null(responses[0].Items);
        Assert.Equal(200, responses[0].Status);
        Assert.Contains("PSMicrosoftEntraID.Users.User", responses[0].ConversionError);
        Assert.Contains("[0].displayName", responses[0].ConversionError);
        Assert.DoesNotContain("S3cr3t", responses[0].ConversionError);
    }

    [Fact]
    public async Task LeavesTheBodiesAsTextWithoutAnElementType()
    {
        var (responses, _) = await Send((_, _) => Task.FromResult(Json(HttpStatusCode.OK, """{"responses":[{"id":"1","status":200,"body":{"value":[{"id":"u1"}]}}]}""")));

        Assert.Null(responses[0].Items);
        Assert.Equal("""{"value":[{"id":"u1"}]}""", responses[0].Body);
    }
}
