import binarylang, nimib, strutils, print, strformat
printColors = false
nbInit
nbText:"""
# Parsing logs with Binarylang

One thing that most developers will have to do at least
once in their life is be asked to parse some logs and extract
some sort of meaningful data from them. How do you do that with
binarylang? Here's an example from some web server logs.
"""
var log = readFile("example.log")
nbText: &"""```
{log}
```"""
nbText: """
That's a lot of stuff to parse. Thankfully, most of it appears to be
between strings, therefore it is pretty straightforward to parse it with
binarylang.
"""
nbCode:
    struct(record):
        s: ip
        s: _ = " - - "
        s: serverTime
        s: _ = """ "GET /?time="""
        s: clientTime
        s: _ = "&random="
        s: random
        s: _ = "&webrtc="
        s: webrtc
        s: _ = "&websocket="
        s: websocket
        s: _ = """ HTTP/1.1" 200 """ 
        s: _
        s: _ = """ "https://588.lan.wtf/start/" """"
        s: useragent
        s: _ = "\"\n"
    print log.toRecord
    echo Record(
        ip: "localhost", serverTime: "500", clientTime: "600", random: "23",
        webrtc: "true", websocket: "true", useragent: "Chrome"
    ).fromRecord
nbText: """
And there you have it. We can not only parse logs, but now we can also generate
them if we wanted to. Lastly, we'll parse the entire thing into a sequence using binarylang.
"""
nbCode:
    struct(logs):
        *record: records{s.atEnd}
    print log.toLogs.records[0..2]
nbText: """
We tell binarylang to keep parsing each log line until we hit the end
of the file (that is what the curly braces after the field indicate.)
"""
nbSave
