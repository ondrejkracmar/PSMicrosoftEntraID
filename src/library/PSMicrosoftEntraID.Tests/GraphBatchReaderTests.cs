using System.Text.Json;
using PSMicrosoftEntraID.Batch;
using Xunit;

namespace PSMicrosoftEntraID.Tests;

/// <summary>
/// GraphBatchReader: one sub-response per entry of a $batch answer, read from the raw JSON without PowerShell
/// objects - status, Retry-After, the raw body, paging links, the item count and the error message of Graph.
/// </summary>
public class GraphBatchReaderTests
{
    [Fact]
    public void ReadsEverySubResponseInTheOrderGraphReturnedThem()
    {
        const string json = """
            {"responses":[
              {"id":"2","status":200,"headers":{},"body":{"value":[{"id":"a"},{"id":"b"}],"@odata.nextLink":"https://graph.microsoft.com/v1.0/users/x/messages?$skiptoken=t1","@odata.deltaLink":"https://graph.microsoft.com/v1.0/users/x/messages/delta?$deltatoken=d1"}},
              {"id":"1","status":429,"headers":{"Retry-After":"7"},"body":{"error":{"code":"TooManyRequests","message":"Slow down"}}}
            ]}
            """;

        var responses = GraphBatchReader.Parse(json);

        Assert.Equal(2, responses.Length);
        var page = responses[0];
        Assert.Equal("2", page.Id);
        Assert.Equal(200, page.Status);
        Assert.True(page.IsSuccess);
        Assert.Equal(2, page.ItemCount);
        Assert.Equal("https://graph.microsoft.com/v1.0/users/x/messages?$skiptoken=t1", page.NextLink);
        Assert.Equal("https://graph.microsoft.com/v1.0/users/x/messages/delta?$deltatoken=d1", page.DeltaLink);
        Assert.Equal(0, page.RetryAfter);
        Assert.Null(page.ErrorMessage);
        using (var body = JsonDocument.Parse(page.Body))
        {
            Assert.Equal(2, body.RootElement.GetProperty("value").GetArrayLength());
        }

        var throttled = responses[1];
        Assert.Equal("1", throttled.Id);
        Assert.Equal(429, throttled.Status);
        Assert.False(throttled.IsSuccess);
        Assert.Equal(7, throttled.RetryAfter);
        Assert.Equal("Slow down", throttled.ErrorMessage);
        Assert.Equal(0, throttled.ItemCount);
    }

    [Fact]
    public void ReadsPropertyNamesIgnoringCase()
    {
        var responses = GraphBatchReader.Parse("""{"Responses":[{"ID":"1","Status":503,"Headers":{"retry-after":"30"},"Body":{"Value":[{}]}}]}""");

        var response = Assert.Single(responses);
        Assert.Equal("1", response.Id);
        Assert.Equal(503, response.Status);
        Assert.Equal(30, response.RetryAfter);
        Assert.Equal(1, response.ItemCount);
    }

    [Theory]
    [InlineData("\"3600\"", 300)]
    [InlineData("3600", 300)]
    [InlineData("12", 12)]
    [InlineData("\"soon\"", 0)]
    [InlineData("\"Wed, 21 Oct 2015 07:28:00 GMT\"", 0)]
    public void ReadsRetryAfterAsAtMostFiveMinutes(string header, int expected)
    {
        var responses = GraphBatchReader.Parse("""{"responses":[{"id":"1","status":429,"headers":{"Retry-After":""" + header + "}}]}");

        Assert.Equal(expected, Assert.Single(responses).RetryAfter);
    }

    [Fact]
    public void ReadsANumericIdAsText()
    {
        Assert.Equal("17", Assert.Single(GraphBatchReader.Parse("""{"responses":[{"id":17,"status":204}]}""")).Id);
    }

    [Fact]
    public void LeavesABodyOfAnotherKindAsItsRawText()
    {
        var responses = GraphBatchReader.Parse("""{"responses":[{"id":"1","status":200,"body":"plain"},{"id":"2","status":204,"body":null},{"id":"3","status":200,"body":[1,2]}]}""");

        Assert.Equal("\"plain\"", responses[0].Body);
        Assert.Equal(0, responses[0].ItemCount);
        Assert.Null(responses[1].Body);
        Assert.Equal("[1,2]", responses[2].Body);
        Assert.Equal(0, responses[2].ItemCount);
    }

    [Fact]
    public void IgnoresLinksAndMessagesThatAreNoStrings()
    {
        var response = Assert.Single(GraphBatchReader.Parse("""{"responses":[{"id":"1","status":400,"body":{"@odata.nextLink":5,"@odata.deltaLink":{"a":1},"value":"x","error":{"message":42}}}]}"""));

        Assert.Null(response.NextLink);
        Assert.Null(response.DeltaLink);
        Assert.Equal(0, response.ItemCount);
        Assert.Null(response.ErrorMessage);
        Assert.Equal(400, response.Status);
    }

    [Fact]
    public void LeavesAMissingOrUnreadableStatusAtZero()
    {
        var responses = GraphBatchReader.Parse("""{"responses":[{"id":"1"},{"id":"2","status":"200"},{"id":"3","status":1.5}]}""");

        Assert.All(responses, response => Assert.Equal(0, response.Status));
        Assert.All(responses, response => Assert.False(response.IsSuccess));
    }

    [Fact]
    public void ReadsAnEmptyResponsesArrayAsNoSubResponse()
    {
        Assert.Empty(GraphBatchReader.Parse("""{"responses":[]}"""));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("{}")]
    [InlineData("""{"responses":{}}""")]
    [InlineData("""{"value":[]}""")]
    [InlineData("[]")]
    public void RefusesAnAnswerWithoutResponses(string json)
    {
        var exception = Assert.Throws<ArgumentException>(() => GraphBatchReader.Parse(json));
        Assert.Equal("json", exception.ParamName);
    }

    [Fact]
    public void RefusesTextThatIsNoJson()
    {
        Assert.ThrowsAny<JsonException>(() => GraphBatchReader.Parse("<html>gateway timeout</html>"));
    }
}
