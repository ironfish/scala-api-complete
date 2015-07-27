from os import walk
from os import listdir
from os.path import isfile
from os.path import join
from os.path import expanduser
import re


#MODIF_PTRN = '(?P<modif>(abstract )?(final )?)?'
#MODIF_PTRN = '((?P<modif>(abstract)|(abstract final)|(final))( )?)?'
#PARMS_PTRN = ' ?(?P<parms>(?!:)(\(([\w:,\[\] <=>\*]*)?\))?(\([\w:,\[\]\(\) =>\*]*\))?)?'
#PARMS_PTRN = ' ?(?P<parms>(?!:)(\(\))?(\([\w:,\[\] <=>\*]*\))?(\([\w:,\[\]\(\) =>\*]*\))?)?'
#PARMS_PTRN = '(?P<parms>(?!:)(?!( \{))( ?\(\))?( ?\([\w:,\[\] <=>\*]*\))?(\([\w:,\[\]\(\) =>\*]*\))?)?'
#PARMS_PTRN = '(?P<parms>(?!:)(?!( \{)) ?(\(\))?(\([\w:,\[\] <=>\*]*\))?(\([\w:,\[\]\(\) =>\*]*\))?)?'
#PARMS_PTRN = '(?P<parms>(!: ?\(\))?(\([\w:,\[\] =>\*]*\))?(\([\w:,\[\]\(\) =>\*]*\))?)?'
#PARMS_PTRN = '( )?(?P<parms>\([\w:,\[\] =>\*]*\)\([\w:,\[\]\(\) =>\*]*\)?)?'

#PTYPE_PTRN = '((?P<ptype>\[[\w: ]+\]) ?)?'
#PTYPE_PTRN = '((?P<ptype>\[[\w:,\[\]<=>\* ]+\]) ?)?'

TYPE_PTRN = '\[[\w:,\[\]<=>\*\+ ]+\]'
PTYPE_PTRN = '((?P<ptype>' + TYPE_PTRN + ') ?)?'
PARMS_PTRN = ' ?(?P<parms>(\(([\w:,\[\]<=>\* ]+)?\)){1,2})?'
RTYPE_PTRN = '((: )(?P<rtype>(?:[\w]+)((\[)([\w:<, \[\]]+)(\]))?))?'
EXTEN_PTRN = '(( ?extends )(?P<extn>[\w:,.\[\] ]+) {)?'

PACKG_PTRN = '(^package )(?P<package>[a-zA-Z\.]*)'
PACKG_REGX = re.compile(PACKG_PTRN, re.MULTILINE)

# The root pattern cannot have any aliases as findall is being used and the entire trait must be captured as a single unit.
CLASS_PTRN = '^((?:abstract )?(?:final )?class(?<=class)(?:(?!\n}).)+(?:\n}))'

CLASS_MODIF_PTRN = '^((?P<modif>(abstract)|(abstract sealed)|(abstract sealed)|(final)|(sealed))( )?)?'
CLASS_NAME_PTRN = 'class (?P<name>[\w]+)'
CLASS_SIGN_PTRN = CLASS_MODIF_PTRN + CLASS_NAME_PTRN + PTYPE_PTRN + PARMS_PTRN + EXTEN_PTRN

CLASS_REGX = re.compile(CLASS_PTRN, re.DOTALL|re.MULTILINE)
CLASS_SIGN_REGX = re.compile(CLASS_SIGN_PTRN, re.DOTALL|re.MULTILINE)

# The root pattern cannot have any aliases as findall is being used and the entire trait must be captured as a single unit.
TRAIT_PTRN = '^((?:abstract )?(?:sealed )?trait(?<=trait)(?:(?!\n}).)+(?:\n}))'
TRAIT_PTRN_ALT = '(?:abstract )?(?:sealed )?trait [\w]+(?:\n)'

TRAIT_MODIF_PTRN = '^((?P<modif>(abstract)|(abstract sealed)|(sealed))( )?)?'
TRAIT_NAME_PTRN = 'trait (?P<name>[\w]+)'
TRAIT_SIGN_PTRN = TRAIT_MODIF_PTRN + TRAIT_NAME_PTRN + EXTEN_PTRN

TRAIT_REGX = re.compile(TRAIT_PTRN, re.DOTALL|re.MULTILINE)
TRAIT_ALT_REGX = re.compile(TRAIT_PTRN_ALT, re.DOTALL|re.MULTILINE)
TRAIT_SIGN_REGX = re.compile(TRAIT_SIGN_PTRN, re.DOTALL|re.MULTILINE)

# The root pattern cannot have any aliases as findall is being used and the entire trait must be captured as a single unit.
OBJ_PTRN = '^((?:final )?object(?<=object)(?:(?!\n}).)+(?:\n}))'

OBJ_MODIF_PTRN = '^((?P<modif>(final))( )?)?'
OBJ_NAME_PTRN = 'object (?P<name>[\w]+)'
OBJ_SIGN_PTRN = OBJ_MODIF_PTRN + OBJ_NAME_PTRN + EXTEN_PTRN

OBJ_REGX = re.compile(OBJ_PTRN, re.DOTALL|re.MULTILINE)
OBJ_SIGN_REGX = re.compile(OBJ_SIGN_PTRN, re.DOTALL|re.MULTILINE)

# NOTE: this picks up nested functions and it should not.
#FUNC_NAME_PTRN = '(def )(?P<func>\w+|==|!=|##)'
FUNC_NAME_PTRN = '^  (final )?(protected )?(implicit )?(override )?(def )(?P<func>\w+|==|!=|##)'
FNUC_PTRN  = FUNC_NAME_PTRN + PTYPE_PTRN + PARMS_PTRN + RTYPE_PTRN
FNUC_REGX  = re.compile(FNUC_PTRN)

# find members
def members( scala ):
    lines = scala.split("\n")
    func_out = "|func: {0}|  |{1}|  |{2}|  |{3}|"
    #func_out = "func: {{{0}}} {{{1}}} {{{2}}} {{{3}}}"
    #func_out = "func: ~{0}~ ~{1}~ ~{2}~ ~{3}~"
    for line in lines:
        func_match = re.search(FNUC_REGX, line)
        if func_match:
            fn = func_match.group('func')
            fpt = func_match.group('ptype')
            fp = func_match.group('parms')
            frt = func_match.group('rtype')
            print func_out.format(fn, fpt, fp, frt)

# find classes
def classes ( scala ):
    class_match = re.findall(CLASS_REGX, scala)
    if class_match:
        class_out = "|class: {0}|  |{1}|  |{2}|  |{3}|  |{4}|"
        for cls in class_match:
            class_sign = re.match(CLASS_SIGN_REGX, cls)
            m = class_sign.group('modif')
            n = class_sign.group('name')
            pt = class_sign.group('ptype')
            p = class_sign.group('parms')
            e = class_sign.group('extn')
            print class_out.format(m, n, pt, p, e)
            print "--------------------------------"
            members(cls)
            print "********************************"
    else:
        print "NO CLASSES FOUND"
        print "********************************"

# find traits with full bodies
def traits ( scala ):
    trait_match = re.findall(TRAIT_REGX, scala)
    trait_out = "|trait: {0}|  |{1}|  |{2}|"
    if trait_match:
        for trt in trait_match:
            trait_sign = re.match(TRAIT_SIGN_REGX, trt)
            m = trait_sign.group('modif')
            n = trait_sign.group('name')
            e = trait_sign.group('extn')
            print trait_out.format(m, n, e)
            print "--------------------------------"
            members(trt)
            print "********************************"
    else:
        print "NO TRAITS FOUND"
        print "********************************"

# find traits without bodies
def traits_alt( scala ):
    trait_match = re.findall(TRAIT_ALT_REGX, scala)
    trait_out = "|alt trait: {0}|  |{1}|  |{2}|"
    if trait_match:
        for trt in trait_match:
            trait_sign = re.match(TRAIT_SIGN_REGX, trt)
            m = trait_sign.group('modif')
            n = trait_sign.group('name')
            e = trait_sign.group('extn')
            print trait_out.format(m, n, e)
            print "--------------------------------"
            members(trt)
            print "********************************"
    else:
        print "NO TRAITS ALTERNATE FOUND"
        print "********************************"

# find objects with full bodies
def objects ( scala ):
    obj_match = re.findall(OBJ_REGX, scala)
    obj_out = "|object: {0}|  |{1}|  |{2}|"
    if obj_match:
        for obj in obj_match:
            obj_sign = re.match(OBJ_SIGN_REGX, obj)
            m = obj_sign.group('modif')
            n = obj_sign.group('name')
            e = obj_sign.group('extn')
            print obj_out.format(m, n, e)
            print "--------------------------------"
            members(obj)
            print "********************************"
    else:
        print "NO OBJECTS FOUND"
        print "********************************"

# find package
def package( scala ):
    package_match = re.search(PACKG_REGX, scala)
    pkg_out = "|package: {0}|"
    if package_match:
        package_name = package_match.group('package')
        print pkg_out.format(package_name)
        print "********************************"
    else:
        print "NO PACKAGE FOUND"
        print "********************************"

# strip multi-line comments their left over blank lines
def strip( scala ):
    BLANK_LINE = re.compile(r"^\n", re.MULTILINE)
    COMMENT = re.compile(r'/\*[^*]*\*+(?:[^/*][^*]*\*+)*/', re.DOTALL | re.MULTILINE)
    scala_clean = re.sub(COMMENT, "", scala)
    scala_clean = re.sub(BLANK_LINE, "", scala_clean)
    return scala_clean

def process(scalafile):
    print "\nprocessing: " + scalafile
    fo = open(scalafile, 'r')
    ft = fo.read()
    fo.close()
    scala_clean = strip(ft)
    package(scala_clean)
    classes(scala_clean)
    traits(scala_clean)
    traits_alt(scala_clean)
    objects(scala_clean)

rootdir = expanduser("~/scratch/scala/src")

#scaladir = rootdir + "/library/scala"
scalafile = rootdir + "/library/scala/AnyVal.scala"
process(scalafile)
scalafile = rootdir + "/library/scala/AnyValCompanion.scala"
process(scalafile)
scalafile = rootdir + "/library/scala/App.scala"
process(scalafile)
scalafile = rootdir + "/library/scala/Array.scala"
process(scalafile)

scalafile = rootdir + "/library-aux/scala/Any.scala"
process(scalafile)
scalafile = rootdir + "/library-aux/scala/AnyRef.scala"
process(scalafile)
scalafile = rootdir + "/library-aux/scala/Nothing.scala"
process(scalafile)
scalafile = rootdir + "/library-aux/scala/Null.scala"
process(scalafile)

