import sys,os,shutil,json,hashlib,zipfile
src,stage,zpath=sys.argv[1:4]
if os.path.exists(stage): shutil.rmtree(stage)
shutil.copytree(src,stage)
old=os.path.join(stage,'Resources/docs/README-RU.md')
if os.path.exists(old): os.remove(old)
open(os.path.join(stage,'Resources/docs/README-EDIT.md'),'w',encoding='utf8',newline='\r\n').write('''# nfUI Survivors Edit

An unofficial edit of nfUI for Azeroth Survivors. The authors of the original code are listed in `Resources/licenses/`.

## Install
1. Delete any old `nfUI` folder.
2. Unzip so that you get `benilla-config/AddOns/nfUI`. In the browser version, pick the zip under Options > AddOns > Install AddOns instead.
3. Enable the addon and start a run.

The first start replaces your earlier nfUI layout. The layout fits your screen by itself; move anything with `/nfui` > Movers.

To remove the edit, delete the folder and install regular nfUI.
''')
man={}
for root,_,fs in os.walk(stage):
    for f in fs:
        rel=os.path.relpath(os.path.join(root,f),stage).replace(os.sep,'/')
        if rel!='Resources/MANIFEST.json': man[rel]=hashlib.sha256(open(os.path.join(root,f),'rb').read()).hexdigest()
json.dump(dict(sorted(man.items())),open(os.path.join(stage,'Resources/MANIFEST.json'),'w',encoding='utf8',newline='\r\n'),indent=2)
with zipfile.ZipFile(zpath,'w',zipfile.ZIP_DEFLATED) as z:
    for root,_,fs in os.walk(stage):
        for f in sorted(fs):
            fp=os.path.join(root,f); z.write(fp,'nfUI/'+os.path.relpath(fp,stage).replace(os.sep,'/'))
print('zip',os.path.getsize(zpath))
