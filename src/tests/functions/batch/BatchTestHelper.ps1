<#
.SYNOPSIS
	Shared helpers of the batch engine tests: a local fake Graph $batch server and a fake connected service.

.DESCRIPTION
	Dot-sourced by the batch engine test files. Nothing here reaches the network:
	- New-TestBatchServer starts a minimal HTTP/1.1 server on a free port of 127.0.0.1 (a TcpListener, no http.sys,
	  no admin rights, no thread job). It answers every POST /v1.0/$batch either by echoing each sub-request as a
	  200 page ({"value":[{"id":"<id>","url":"<url>"}]}) after -DelayMilliseconds, or - with -Hang - never. It counts
	  the envelopes it received and the most that were open at the same time.
	- Enable-TestHttpLoopback lists 127.0.0.1 in the private test hook of [PSMicrosoftEntraID.Batch.GraphBatchClient]
	  (reached through reflection only), so the client accepts the plain-http loopback server; -Disable empties it.
	- Set-TestBatchService points a fake token of the module at a URL; Assert-TestLocalService refuses to go on
	  unless the service points to the local server (general/NoNetwork.Tests.ps1 relies on it).
#>

if (-not ('PSMicrosoftEntraID.Tests.FakeBatchServer' -as [type])) {
	Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Tests
{
    public sealed class FakeBatchServer : IDisposable
    {
        private readonly TcpListener listener = new TcpListener(IPAddress.Loopback, 0);
        private readonly CancellationTokenSource stop = new CancellationTokenSource();
        private readonly List<TcpClient> clients = new List<TcpClient>();
        private int open;
        private int maxOpen;
        private int envelopes;

        public FakeBatchServer(bool hang, int delayMilliseconds)
        {
            Hang = hang;
            DelayMilliseconds = delayMilliseconds;
            listener.Start();
            _ = AcceptAsync();
        }

        public bool Hang { get; }
        public int DelayMilliseconds { get; }
        public string Url => "http://127.0.0.1:" + ((IPEndPoint)listener.LocalEndpoint).Port;
        public int Envelopes => Volatile.Read(ref envelopes);
        public int Open => Volatile.Read(ref open);
        public int MaxOpen => Volatile.Read(ref maxOpen);
        public List<string> Bodies { get; } = new List<string>();

        private async Task AcceptAsync()
        {
            while (!stop.IsCancellationRequested)
            {
                TcpClient client;
                try { client = await listener.AcceptTcpClientAsync(stop.Token); }
                catch { return; }
                lock (clients) { clients.Add(client); }
                _ = ServeAsync(client);
            }
        }

        private async Task ServeAsync(TcpClient client)
        {
            try
            {
                var stream = client.GetStream();
                while (!stop.IsCancellationRequested)
                {
                    var head = await ReadHeadAsync(stream);
                    if (head == null) return;
                    int length = 0;
                    foreach (var line in head.Split("\r\n"))
                    {
                        if (line.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase)) length = int.Parse(line.Substring(15).Trim());
                    }
                    var buffer = new byte[length];
                    var read = 0;
                    while (read < length)
                    {
                        var n = await stream.ReadAsync(buffer, read, length - read, stop.Token);
                        if (n == 0) return;
                        read += n;
                    }
                    var body = Encoding.UTF8.GetString(buffer);
                    lock (Bodies) { Bodies.Add(body); }
                    Interlocked.Increment(ref envelopes);
                    var now = Interlocked.Increment(ref open);
                    int seen;
                    while ((seen = Volatile.Read(ref maxOpen)) < now && Interlocked.CompareExchange(ref maxOpen, now, seen) != seen) { }
                    try
                    {
                        if (Hang) { await Task.Delay(Timeout.Infinite, stop.Token); }
                        if (DelayMilliseconds > 0) await Task.Delay(DelayMilliseconds, stop.Token);
                    }
                    finally { Interlocked.Decrement(ref open); }
                    var answer = Encoding.UTF8.GetBytes(Echo(body));
                    var header = Encoding.ASCII.GetBytes("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " + answer.Length + "\r\n\r\n");
                    await stream.WriteAsync(header, 0, header.Length, stop.Token);
                    await stream.WriteAsync(answer, 0, answer.Length, stop.Token);
                }
            }
            catch { }
            finally { client.Dispose(); }
        }

        private async Task<string> ReadHeadAsync(NetworkStream stream)
        {
            var bytes = new List<byte>();
            var one = new byte[1];
            while (true)
            {
                var n = await stream.ReadAsync(one, 0, 1, stop.Token);
                if (n == 0) return null;
                bytes.Add(one[0]);
                var c = bytes.Count;
                if (c >= 4 && bytes[c - 4] == 13 && bytes[c - 3] == 10 && bytes[c - 2] == 13 && bytes[c - 1] == 10) return Encoding.ASCII.GetString(bytes.ToArray());
            }
        }

        private static string Echo(string body)
        {
            var responses = new List<object>();
            using (var document = JsonDocument.Parse(body))
            {
                foreach (var request in document.RootElement.GetProperty("requests").EnumerateArray())
                {
                    var id = request.GetProperty("id").GetString();
                    var url = request.GetProperty("url").GetString();
                    responses.Add(new { id, status = 200, body = new { value = new[] { new { id = "item-" + id, displayName = url } } } });
                }
            }
            return JsonSerializer.Serialize(new { responses });
        }

        public void Dispose()
        {
            stop.Cancel();
            listener.Stop();
            lock (clients) { foreach (var client in clients) client.Dispose(); }
        }
    }
}
'@
}

function New-TestBatchServer {
	param ([switch]$Hang, [int]$DelayMilliseconds = 0)
	[PSMicrosoftEntraID.Tests.FakeBatchServer]::new($Hang.IsPresent, $DelayMilliseconds)
}

function Enable-TestHttpLoopback {
	# The private test hook of the client: loopback hosts it may reach over plain http. No public way in.
	param ([switch]$Disable)
	$field = [PSMicrosoftEntraID.Batch.GraphBatchClient].GetField('HttpTestHosts', [System.Reflection.BindingFlags]'NonPublic, Static')
	$hosts = $field.GetValue($null)
	if ($Disable) {
		[bool] $removed = $false
		$null = $hosts.TryRemove('127.0.0.1', [ref]$removed)
	}
	else { $null = $hosts.TryAdd('127.0.0.1', $true) }
}

function Set-TestBatchService {
	# A fake connected token for -Service, pointing at -Url; -Remove takes it away again.
	param ([string]$Service = 'PSMicrosoftEntraID.Test', [string]$Url, [switch]$Remove)
	& (Get-Module PSMicrosoftEntraID) {
		param ($Service, $Url, $Remove)
		if ($Remove) { $script:_EntraTokens.Remove($Service); return }
		$fakeToken = [pscustomobject]@{ Service = $Service; ServiceUrl = $Url }
		Add-Member -InputObject $fakeToken -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer test'; 'Content-Type' = 'application/json' } }
		$script:_EntraTokens[$Service] = $fakeToken
	} $Service $Url $Remove.IsPresent
}

function Assert-TestLocalService {
	# Throws unless -Service points to a local test server - the guard before a test sends $batch envelopes through
	# the parallel path, which no mock catches.
	param ([string]$Service = 'PSMicrosoftEntraID.Test')
	[string] $url = & (Get-Module PSMicrosoftEntraID) { param ($Name) [string]$script:_EntraTokens[$Name].ServiceUrl } $Service
	if ($url -notmatch '^http://127\.0\.0\.1:\d+(/|$)') { throw "The service $Service points to '$url', not to the local test server." }
}
