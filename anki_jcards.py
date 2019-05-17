#! /usr/bin/env python2
# coding=utf-8

# Anki japanese cards import script
#
# Scrape study guide pages from http://www.sosekiproject.org/index.html
# in order to create input files ready for import by Anki.
#
# In Anki add Furigana/Prefix fields. Cards setup:
#
# <span class="furigana">{{Prefix}}</span>{{Front}}
#
# .card {
#  ...
#  font-size: 130px;
#  ...
# }
#
# .furigana {
#  font-size: 50px;
# }
#
# .verso {
#  font-size: 30px;
# }
#
# {{FrontSide}}
# <div class="furigana">{{Furigana}}</div>
# <hr id=answer>
# <div class="verso">{{Back}}</div>

from lxml import html
import requests
import codecs
import sys

UTF8Writer = codecs.getwriter('utf8')
sys.stdout = UTF8Writer(sys.stdout)

# use this as raw_input prints to STDOUT
sys.stderr.write(str('URL: '))
url = raw_input()
if not url:
   url = 'http://www.sosekiproject.org/shortworks/tendreams/tendreams-001.html'

page = requests.get(url)
tree = html.fromstring(page.content)

words  = tree.xpath('//span[not(ancestor::p[@class="japanese"]) and @class="vocabdef" and descendant::ruby]')
words2 = tree.xpath('//span[not(ancestor::p[@class="japanese"]) and @class="vocabdef" and not(descendant::ruby)]')

# prefix | kanji | furigana | text
for word in words:

   # for .text/tail properties, check the docs:
   # https://lxml.de/api/lxml.etree._Element-class.html#prefix
   prefix = word.text
   if prefix == None:
      prefix = ''

   rubies = word.xpath('.//ruby')
   rts = '.'.join(word.xpath('.//ruby/rt/text()'))

   line = prefix + '|'
   suffixes = ''

   for ruby in rubies[:-1]:
      suffix = ruby.tail
      if suffix != None:
         suffixes += suffix
         line += ''.join(ruby.xpath('rb/text()')) + suffix
      else:
         if len(rubies[:-1]) > 0:
            line += ''.join(ruby.xpath('rb/text()')) + '.'
         else:
            line += ''.join(ruby.xpath('rb/text()'))

   suffix = rubies[-1].tail
   if suffix != None:
      line += ''.join(rubies[-1].xpath('rb/text()')) + '|' + rts + '|' + suffix
   else:
      line += ''.join(rubies[-1].xpath('rb/text()')) + '|' + rts + '|'

   print line

# --- | hiragana | --- | text
for h in words2:
   print '|' + ''.join(h.xpath('text()')).replace(u' ', '||')
