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
cmdpkg = "call scalaapi#package('{0}', '{1}', '[p]', '{2}', [])"
cmdcls = "call scalaapi#class('{0}', '{1}', '[c]', '{2}', [])"
cmdtrt = "call scalaapi#trait('{0}', '{1}', '[t]', '{2}', [])"
cmdobj = "call scalaapi#object('{0}', '{1}', '[o]', '{2}', [])"
procmsg = "processing {0} ....."

for curdir, subdirs, files in walk(startdir):
    files = [f for f in files if not f == 'package.html']
    package = curdir.replace(scalalibdir, '').replace('/','.')
    print procmsg.format(package)
    packagefile = open(rootdir + package + '.vim', 'w')
    packagefile.write(cmdpkg.format(package, '', '') + "\n")
    for f in files:
        name = f.replace('$$', '.').replace('$', '').replace('.html', '')
        fo = open(join(curdir,f), 'r')
        ft = fo.read()
        fo.close()
        tree = html.fromstring(ft)
        kind = tree.xpath('//body/h4[@id="signature"]/span[@class="modifier_kind"]/span[@class="kind"]/text()')
        #inherits = tree.xpath('//body/h4[@id="signature"]/span[@class="symbol"]/span[@class="result"]/a[@class="extype"]/text()')
        tparams = tree.xpath('//body/h4[@id="signature"]/span[@class="symbol"]/span[@class="tparams"]//text()')
        jtparams = "".join(tparams)
        if kind[0] == 'trait':
            packagefile.write(cmdtrt.format(name, package, jtparams) + "\n")
        elif kind[0] == 'class':
            packagefile.write(cmdcls.format(name, package, jtparams) + "\n")
        elif kind[0] == 'object':
            packagefile.write(cmdobj.format(name, package, jtparams) + "\n")
    packagefile.close

print "Done!"

