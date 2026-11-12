using System.Runtime.CompilerServices;

// The unit tests (src/library/PSMicrosoftEntraID.Tests) swap the HTTP handler of GraphBatchClient for an in-process
// fake, so no test reaches the network. Nothing outside the test assembly sees the internal members.
[assembly: InternalsVisibleTo("PSMicrosoftEntraID.Tests")]
