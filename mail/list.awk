BEGIN {
   print "<!DOCTYPE html>"
   print "<html>"
   print "<head>"
   print "<title>Teams</title>"
   print "<meta charset=\"utf-8\" />"
   print "<style type=\"text/css\">"
   print "dt {"
   print "  font-weight: bold;"
   print "}"
   print "</style>"
   print "</head>"
   print "<body>"
   print "<dl>"
}

{
   sub(/@.*/, "")
   gsub(/\./, " ")

   if (/:/)
      sub(".*", "<dt>&</dt>")
   else if (/.+[^:]$/)
      sub(".*", "<dd>&</dd>")
   else
      sub(".*", "<br />")

   print
}

END {
   print "</dl>"
   print "</body>"
   print "</html>"
}
