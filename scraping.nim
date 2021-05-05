import binarylang, nimib, strutils, print, strformat
printColors = false
nbInit
nbText:"""
# Webscraping with Binarylang

Alright! Let's move onto the next problem, shall we?
A common real world problem that many people run into is extracting
information from a webpage. This is (usually) known as webscraping. There are a few
ways to do it, such as regex and using query selectors by parsing the DOM.

Anyway, I've got some HTML that looks like this:
"""
var website = readFile("anime.html")
nbText: &"""
```html
{website[0..3000]}
...
```
"""
nbText: """
Oh boy, this is a mess. There is some non-standard stuff going on within
the title attribute, having an entire other element inside of it.

What we want: A list of shows, and the watch status (how many episodes have been watched).
Hm, it looks like the title is between `<h5 class='theme-font'>` and `</h5>`, and the 
watch status is also between some strings. Let's try it!
"""
nbCode:
  struct(show):
    s: _ # skip until we see the next field
    s: _ = "<h5 class='theme-font'>"
    s: title
    s: _ = "</h5>"
    s: _
    s: _ = "Watching - "
    s: seen
    s: _ = "/"
    s: total
    s: _ = " eps"
    s: _
    s: _ = "</li>" # Read until the end of the item
  print website.toShow

nbText: """
Wasn't that super easy! You don't need to parse the HTML dom, don't need
to figure out any regex, and you get a normal Nim type to work with! Now, let's
generalize this to all of the shows.
"""
nbCode:
  struct(information):
    *show: {shows}
    s: _ = "</ul>" # Ends when the list ends
  print website.toInformation
nbText: """
And that's it! The only tricky part is figuring out when to stop parsing
but so long as the website has some sort of structure this is pretty doable.
"""
nbSave
