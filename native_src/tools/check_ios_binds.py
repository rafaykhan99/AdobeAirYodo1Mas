#!/usr/bin/env python3
"""Maintainer tool: check an IPA's main binary against the real iOS SDK.

The AIR SDK links iOS apps against its own (iOS 17-era) system stubs, which
can bind a symbol to a library that no longer exports it on current iOS
(that is how nw_interface_get_type ended up bound to libSystem). This script
lists every (library, symbol) import of a linked binary that the current Xcode
iOS SDK (.tbd files) does not export from that library.

Usage (macOS with Xcode):
    unzip -q MyGame.ipa -d /tmp/ipa
    python3 tools/check_ios_binds.py /tmp/ipa/Payload/MyGame.app/MyGame

Known, harmless results for this ANE (verified on device, iOS 27):
  - libswiftCoreGraphics CGFloat symbols (still provided at runtime)
  - NO-TBD weak libswiftMetricKit / libswiftWebKit (weak-linked)
Any STRONG import from libSystem means a new symbol needs a forwarder in
ios/stubs/Yodo1MasLinkFixes.c.
"""
import sys,subprocess,re,os,glob
binary=sys.argv[1]
SDK=subprocess.check_output(['xcrun','--sdk','iphoneos','--show-sdk-path'],text=True).strip()
# map install-name -> tbd path
inst={}
for tbd in glob.glob(SDK+'/usr/lib/**/*.tbd',recursive=True)+glob.glob(SDK+'/System/Library/**/*.tbd',recursive=True):
    try: txt=open(tbd,errors='ignore').read()
    except: continue
    for m in re.finditer(r"install-name:\s*'?([^'\n]+)'?",txt):
        inst.setdefault(m.group(1).strip(),tbd)
cache={}
def exports(name,seen=None):
    if name in cache: return cache[name]
    seen=seen or set()
    if name in seen: return set()
    seen.add(name)
    tbd=inst.get(name); syms=set()
    if not tbd: cache[name]=None; return None
    txt=open(tbd,errors='ignore').read()
    # only the document for this install name
    docs=txt.split('--- !tapi-tbd')
    doc=next((d for d in docs if re.search(r"install-name:\s*'?"+re.escape(name),d)),txt)
    for m in re.finditer(r"(symbols|weak-symbols|thread-local-symbols|objc-classes|objc-eh-types|objc-ivars):\s*\[([^\]]*)\]",doc,re.S):
        kind=m.group(1)
        for s in re.findall(r"'([^']+)'|([^\s,']+)",m.group(2)):
            s=s[0] or s[1]
            if not s: continue
            if kind=='objc-classes': syms|={'_OBJC_CLASS_$_'+s,'_OBJC_METACLASS_$_'+s}
            elif kind=='objc-eh-types': syms.add('_OBJC_EHTYPE_$_'+s)
            elif kind=='objc-ivars': syms.add('_OBJC_IVAR_$_'+s)
            else: syms.add(s)
    for m in re.finditer(r"re-exports:\s*\n(.*?)(?=\n\S|\Z)",doc,re.S):
        for lib in re.findall(r"libraries:\s*\[([^\]]*)\]",m.group(1),re.S):
            for l in re.findall(r"'([^']+)'|([^\s,']+)",lib):
                l=l[0] or l[1]
                sub=exports(l,seen)
                if sub: syms|=sub
    for lib in re.findall(r"reexported-libraries:\s*\n\s*-\s*targets:.*?\n\s*libraries:\s*\[([^\]]*)\]",doc,re.S):
        for l in re.findall(r"'([^']+)'|([^\s,']+)",lib):
            l=l[0] or l[1]; sub=exports(l,seen)
            if sub: syms|=sub
    cache[name]=syms; return syms
libs=[l.strip().split(' (')[0] for l in subprocess.check_output(['otool','-L',binary],text=True).splitlines()[1:]]
out=subprocess.check_output(['xcrun','dyld_info','-fixups',binary],text=True)
short={}
for l in libs: short.setdefault(os.path.basename(l).split('.')[0],l)
bad={}
seen=set()
for line in out.splitlines():
    m=re.search(r'bind\s+(\S+?)/(\S+)(\s+\[weak-import\])?',line)
    if not m: continue
    lib,sym,weak=m.group(1),m.group(2),m.group(3)
    if (lib,sym) in seen: continue
    seen.add((lib,sym))
    if lib.startswith('<') : continue
    full=short.get(lib) or next((x for x in libs if os.path.basename(x).startswith(lib)),None)
    if not full or full.startswith('@'): continue
    ex=exports(full)
    if ex is None: bad.setdefault(('NO-TBD',full),[]).append(sym); continue
    if sym not in ex: bad.setdefault((full,'weak' if weak else 'STRONG'),[]).append(sym)
for k,v in sorted(bad.items()):
    print(k, len(v), v[:8])
print('checked',len(seen),'imports')
