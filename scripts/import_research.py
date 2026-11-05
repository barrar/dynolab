#!/usr/bin/env python3
"""Validate research JSON and generate the typed, bundled comparison library."""
import json, math
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent

def q(value):
    return json.dumps(str(value or ''), ensure_ascii=False).replace('$', r'\$')

def norm(text):
    import unicodedata
    return ''.join(c for c in unicodedata.normalize('NFKD', text).lower() if c.isalnum())

catalog=json.loads((ROOT/'docs/catalog-families.json').read_text())
aliases=catalog.get('aliases',{})
families=catalog.get('families',{})
entries=[]
for name in ['adventure-expansion.json','dual-sport-expansion.json','ktm390-expansion.json','catalog-expansion.json','tuning-expansion.json']:
    path=ROOT/'docs'/name
    if not path.exists():
        continue
    data=json.loads(path.read_text())
    if isinstance(data,dict):
        data=data.get('entries',data.get('configurations',[]))
    entries.extend(data)
for e in entries:
    e['bikeId']=aliases.get(e['bikeId'],e['bikeId'])
ids=set(); bike_map={}; weights=[]; configs=[]
for e in entries:
    assert e['id'] not in ids, f"Duplicate configuration: {e['id']}"
    ids.add(e['id'])
    for key in ['id','bikeId','make','name','years','displacement','source']:
        assert e.get(key), (e.get('id'),key)
    source=e['source']
    assert source['url'].startswith('https://'), e['id']
    points=e.get('points') or []
    for i,p in enumerate(points):
        assert len(p)==3 and all(isinstance(n,(float,int)) and math.isfinite(n) and n>=0 for n in p),(e['id'],p)
        if i: assert p[0] > points[i-1][0], (e['id'],'RPM order')
    asset=source.get('asset','')
    if asset: assert (ROOT/asset).is_file(),(e['id'],asset)
    if points: assert len(points)>1, e['id']
    bid=e['bikeId']
    if bid not in ('honda','ktm'):
        bike_map.setdefault(bid,e)
    weight=e.get('weightLb') or 0
    if weight and not e.get('weightBasis'):
        raise ValueError(f"Weight lacks basis: {e['id']}")
    wid=e.get('defaultWeightPresetId') or 'research-weight-'+e['id']
    label=e.get('weightLabel') or f"{e['years']} weight reference"
    label=catalog.get('weightLabels',{}).get(wid,label)
    if not e.get('defaultWeightPresetId'):
        weights.append(f"  WeightPreset({q(wid)}, {q(bid)}, {q(label)}, {float(weight)}, {q(e.get('weightBasis') or 'No verified wet reference weight available. Source-only record.')}, {q(e.get('weightSourceUrl') or source['url'])}),")
    points_string=',\n      '.join(f'DynoPoint({float(r)}, {float(h)}, {float(t)})' for r,h,t in points)
    source_string='DynoSource('+', '.join(f'{key}: {q(source.get(key,""))}' for key in ['publisher','url','imageUrl','asset','method','caveat'])+')'
    fields={
        'id':e['id'],'bikeId':bid,'name':e.get('configName','Stock'),
        'shortName':e.get('shortName','Stock'), 'reportedPeaks':e.get('reportedPeaks','No verified dyno peak data.'),
        'notes':e.get('notes',''), 'category':e.get('category','390 research'),
        'selectionReason':e.get('selectionReason',''), 'usSourceUrl':e.get('usSourceUrl',''),
        'measurementBasis':e.get('measurementBasis','Rear wheel' if points else 'No measured curve'),
        'defaultWeightPresetId':wid,
        'baselineConfigId':e.get('baselineConfigId',''),
        'gainSummary':e.get('gainSummary',''),
    }
    configs.append('  Configuration(\n    '+',\n    '.join(f'{k}: {q(v)}' for k,v in fields.items())+
        ',\n    upgraded: '+str(bool(e.get('upgraded'))).lower()+',\n    parts: ['+', '.join(q(p) for p in e.get('parts',['Factory hardware']))+'],\n    source: '+source_string+',\n    points: [\n      '+points_string+'\n    ],\n  ),')

# The selections deliberately span different budgets, sizes, and riding priorities.
adv=[('KTM 390 Adventure R','ktm-stock','Accessible lightweight adventure option; current Euro 5b engine reference.','ktm-adventure')]
ds=[('Honda CRF300L','honda-stock','Manageable, economical dual sport with a directly sourced stock baseline.','honda-standard'),
    ('KTM 390 Enduro R','ktm-stock','Lightweight adventure-derived dual sport; clearly labeled Euro 5b engine reference.','ktm-enduro')]
for e in entries:
    if e.get('upgraded') or e.get('editorialPick') is False: continue
    pick=(f"{e['make']} {e['name']}",e['id'],e.get('selectionReason') or 'Editorial U.S. model-family selection; exact published dyno test year is shown.',None)
    if e.get('category')=='Adventure': adv.append(pick)
    if e.get('category')=='Dual sport': ds.append(pick)
assert len(adv)<=10,(len(adv),'adventure count')
assert len(ds)<=10,(len(ds),'dual sport count')
def picks(name,data):
    return 'const '+name+' = <EditorialPick>[\n'+''.join('  EditorialPick('+', '.join(q(x) for x in row[:3])+(', weightPresetId: '+q(row[3]) if row[3] else '')+'),\n' for row in data)+'];\n'
output="// Generated from docs/*-expansion.json by scripts/import_research.py.\npart of 'dyno_data.dart';\n\n"
for bid,e in bike_map.items():
    e.update(families.get(bid,{}))
for w in catalog.get('weights',[]):
    assert w['weightLb']>0 and w['sourceUrl'].startswith('https://'),w
    weights.append('  WeightPreset('+', '.join(q(w[k]) if k!='weightLb' else str(float(w[k])) for k in ['id','bikeId','label','weightLb','basis','sourceUrl'])+'),')
output+='const researchedBikes = <Bike>[\n'+''.join('  Bike('+', '.join(q(e[k]) for k in ['bikeId','make','name','years','displacement'])+'),\n' for e in bike_map.values())+'];\n\n'
output+='const researchedWeights = <WeightPreset>[\n'+'\n'.join(weights)+'\n];\n\n'
output+='final researchedConfigurations = <Configuration>[\n'+'\n'.join(configs)+'\n];\n\n'
output+=picks('adventurePicks',adv)+'\n'+picks('dualSportPicks',ds)
coverage=json.loads((ROOT/'docs/tune-coverage.json').read_text())
assert set(coverage)==set(bike_map)|{'honda','ktm'},'Every family needs a research result'
for e in entries:
    if e.get('baselineConfigId'):
        assert e['baselineConfigId'] in ids or e['baselineConfigId'] in ('honda-stock','ktm-stock'),e['id']
output+='\nconst tuneResearch = <String, String>{\n'+''.join('  '+q(bid)+': '+q(note)+',\n' for bid,note in coverage.items())+'};\n'
(ROOT/'lib/researched_data.dart').write_text(output)
print(f'Imported {len(entries)} records, {sum(bool(e.get("points")) for e in entries)} curves, {len(bike_map)} new families, {len(adv)} adventure picks, {len(ds)} dual-sport picks.')
