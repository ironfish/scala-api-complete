from os import walk
from os import listdir
from os.path import isfile
from os.path import join
from os.path import expanduser
import re
from lxml import html
from lxml import etree
rootdir = expanduser("~/scratch/")
scalalibdir = rootdir + "scala-docs-2.11.4/api/scala-library/"
startdir = scalalibdir + "scala"
anyvalhtml = startdir + "/AnyVal.html"

fo = open(anyvalhtml, 'r')
ft = fo.read()
fo.close()
tree = html.fromstring(ft)
comment = tree.xpath('//body/div[@class="fullcommenttop"]//text()')
jcomment = "".join(comment)
print jcomment
