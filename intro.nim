import binarylang, sequtils, strutils, print, json, tables
printColors = false
import nimib
nbInit
nbText: """
## Introduction to Binarylang
So one day, I'm working on a project and I realize that I need to do some socket level HTTP
request sending and receiving. Since this is at the socket level, I can't really use the code that is
a part of the standard library as easily, since parsing HTTP stuff is baked into other functions.

So, I'm given a response that looks a little something like this:
"""

var msg = """
HTTP/1.1 404 Not Found
Date: Sun, 18 Oct 2012 10:36:20 GMT
Server: Apache/2.2.14 (Win32)
Content-Length: 10
Connection: Closed
Content-Type: text/html; charset=iso-8859-1

here is me"""
nbCode:
  echo msg

nbText: """
Now there are quite a few ways to parse this. Regex is probably a pretty good cross language
way of handling it, although then you'll have [two problems instead of one.](https://blog.codinghorror.com/regular-expressions-now-you-have-two-problems/)
Nim's `scanf` module would also probably handle this pretty well, as would some sort
of generic parser using `parseutils` or `npeg`.

However, none of these tools really address an important issue: how do I serialize the object?

If I want to be able to both parse the HTTP header from a server, and create one as a client,
shouldn't that code be pretty much identical? Nim has strong meta-programming capabilities,
why can't I just define what my format looks like and have a parser/serializer generated from that?

Enter [binarylang](https://github.com/sealmove/binarylang).

Now, I can *declare* what my type looks like, and let it generate everything else for me. Let's try parsing just
the first line in that HTTP header, shall we?
"""
nbCode:
  struct(http):
    s: _ = "HTTP/"
    s: version
    s: _ = " "
    s: code
    s: _ = " "
    s: msg
    s: _ = "\n"
  print toHTTP(msg)

nbText: """
So what's going on here? First, we tell binarylang to go ahead and create a type called http, for parsing.
Next, we use it to define the format of a header. A header has a string, that starts with HTTP/, and then a version.
The version is also a string, so we prefix it with a `s`. Then, we look for a space to separate the two, and continue on
in a similar fashion. Here, everything we are parsing happens to behave like a string, so we can have all the types be string.
An underscore (_) simply signifies that we don't care enough about that value to name it. It is good for what are called
"magic" values, or to skip to the field you actually care about.

Since binarylang operates on bitstreams, we turn the string into one, and then tell it to parse into an object.

So, we have a functioning parser for the example header. What do we do if we wanted to generate a header though?
  """

nbCode:
  var httpHeader = HTTP(version: "1.1", code: "200", msg: "OK")
  echo httpHeader.fromHTTP
nbText: """Wow. It pretty much just works."""
nbText: """
Next are the headers. While we could proceed as we did earlier, for each of the headers, it won't quite work.
HTTP headers can be in a different order, and more importantly, they can be *anything*. So, we need some way to parse
a sequence of headers. First, let's define a type for the header itself.
"""
nbCode:
  struct(header):
    s: name
    s: _ = ": "
    s: value
    s: _ = "\n"
  print "Server: Apache/2.2.14 (Win32)\n".toHeader
nbText: """
Fantastic! We now have a way to parse a single header line. Of course, we need to handle a list of these
somehow. Thankfully, binarylang has us covered.
"""

nbCode:
  struct(http2):
    s: _ = "HTTP/"
    s: version
    s: _ = " "
    s: code
    s: _ = " "
    s: msg
    s: _ = "\n"
    *header: {headers}
    s: _ = "\n"
  print msg.toHTTP2

nbText: """
Hold on, what's going on here? What's up with all of the weird * and {}? Doesn't * mean a 
public property in Nim?

The * can be used for two different things in binarylang. It can be used to either make a field public,
or to refer to an existing parser being used as a type. In this case, we can use it to refer to the header
type that we defined earlier. As for the `{headers}`, the curly braces denote "read into a seq until the next value can be parsed". 
So, what happens is that we try to parse each header, and after parsing each one we see if the next thing on the stream is a
newline. If it is, we stop parsing headers and finish, otherwise we keep adding on to that seq. Since HTTP headers use newlines
to delimit the different sections, this works out fine.

  """
# However, working with a sequence of headers is a little strange. 
# It would be nice if it could be accessed as if it were a table in Nim,
# with a string to string mapping. Thankfully, binarylang provides `@get` and `@set`, which define procs that can
# be ran on field access or assignment. First, let's define some helper procs to convert between the two.
# nbCode:
#   type myTable = TableRef[string, string]
#   template tableHeaderGet(parse, parsed, output: untyped) =
#     parse
#     var tmp = newTable[string, string]()
#     for header in parsed:
#       tmp[header.name] = header.value
#     output = tmp
#   template tableHeaderPut(encode, encoded, output: untyped) =
#     var tmp: seq[Header]
#     for name, value in encoded:
#       tmp.add(Header(name: name, value: value))
#     output = tmp
#     encode
#   # proc toTable(headers: seq[Header]): auto =
#   # proc toHeaders(headers: TableRef[string, string]): seq[Header] =
#   #   for name, value in headers:
#   #     result.add(Header(name: name, value: value))
#   # print msg.toHTTP2.headers.toTable
#   # print {"Content-Length": "10"}.newTable.toHeaders
# nbText: """
# I'm using a `TableRef` here due to the `print` macro from [treeform](https://github.com/treeform/print/blob/master/tests/test.nim#L88)
# currently being broken on normal tables.
#
# Anyway, how do we hook this up to have a nicer interface? Now, our type looks like this:
#   """
# nbCode:
#   struct(http3):
#     s: _ = "HTTP/"
#     s: version
#     s: _ = " "
#     s: code
#     s: _ = " "
#     s: msg
#     s: _ = "\n"
#     *header {tableHeader[myTable]}: {headers}
#     # *header {@get: _.toTable, @set: _.toHeaders}: {headers}
#     s: _ = "\n"
#   echo msg.toHTTP3.headers["Content-Length"]
# nbText: """
# That's pretty neat! All that's missing now is the actual, you know, content bit. We want to read a string
# that is as long as the content length. Here's what that looks like:
# """
# nbCode:
#   struct(http4):
#     s: _ = "HTTP/"
#     s: version
#     s: _ = " "
#     s: code
#     s: _ = " "
#     s: msg
#     s: _ = "\n"
#     *header {@get: _.toTable, @set: _.toHeaders}: {headers}
#     s: _ = "\n"
#     s: content(headers["Content-Length"].parseInt)
#   print msg.toHTTP4
# nbText: """We can now parse an entire HTTP response. Remember how at the start I said that we can also use
# this to serialize a full HTTP response? Let's try that.
# ```nim
#   print HTTP4(version: "1.1", code: "200", msg: "OK", content: "Here I am!").fromHTTP4
#   # Error: unhandled exception: key not found: Content-Length [KeyError]
# ```
# This doesn't quite work. We could provide the actual Content-Length manually, but that's
# a hassle, and somewhat error prone. Instead, we can try using `@hook` from binarylang, which
# runs code whenever a field is mutated.
# """
# nbCode:
#   proc updateLength(headers: TableRef[string, string], length: string): auto =
#     headers["Content-Length"] = $length.len
#     return headers
#   struct(http5):
#     s: _ = "HTTP/"
#     s: version
#     s: _ = " "
#     s: code
#     s: _ = " "
#     s: msg
#     s: _ = "\n"
#     *header {@get: _.toTable, @set: _.toHeaders}: {headers}
#     s: _ = "\n"
#     s {@hook: (headers = headers.updateLength(_))}: content(headers["Content-Length"].parseInt)
#   var response = HTTP5(version: "1.1", code: "200", msg: "OK")
#   response.content = "Here I am!"
#   echo response.fromHTTP5
nbSave
