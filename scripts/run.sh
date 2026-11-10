#!/bin/bash
# usage: run.sh <task:windmill|pelican> <effort>
T=$1; E=$2; D=/tmp/exaone-bench/$T-$E; mkdir -p $D
if [ $T = windmill ]; then
P="index.html 파일 하나로 Three.js(CDN, ES module importmap 사용) 3D 장면을 만들어줘. 내용: 언덕 위의 풍차. 풍차는 돌로 된 원통형 몸통, 원뿔 지붕, 지붕 앞쪽에 붙은 4개의 날개가 실제로 회전해야 해. 날개는 몸통과 겹치지 않게 앞으로 튀어나온 축에 달려 있어야 해. 주변에 나무 5그루(줄기+잎), 잔디 지면, 하늘색 배경, 그림자가 드리우는 방향광. OrbitControls로 마우스 회전 가능하게. 외부 모델 파일 없이 기본 도형만 사용. 완성된 HTML 전체를 코드블록 하나로 출력해줘."
else P="Generate an SVG of a pelican riding a bicycle"; fi
python3 -I -c "import json,sys; json.dump({'model':'k-exaone_v2.5','max_tokens':64000,'stream':True,'stream_options':{'include_usage':True},'reasoning_effort':sys.argv[2],'messages':[{'role':'user','content':sys.argv[1]}]},open(sys.argv[3],'w'),ensure_ascii=False)" "$P" "$E" $D/req.json
S=$(date +%s)
curl -sN -m 2400 https://api.exaone.ai/v1/chat/completions -H "Authorization: Bearer $EXAONE_API_KEY" -H 'Content-Type: application/json' --data-binary @$D/req.json > $D/stream.txt
echo "$T-$E ELAPSED $(( $(date +%s)-S ))s"
python3 -I - "$D" "$T" <<'PY'
import json,re,sys
D,T=sys.argv[1],sys.argv[2]; r=c=''; u=None
for l in open(D+'/stream.txt',encoding='utf-8',errors='ignore'):
    if not l.startswith('data: {'): continue
    try: d=json.loads(l[6:])
    except: continue
    for ch in d.get('choices',[]):
        dl=ch.get('delta',{}); r+=dl.get('reasoning_content') or ''; c+=dl.get('content') or ''
    if d.get('usage'): u=d['usage']
open(D+'/content.txt','w').write(c)
if T=='windmill':
    m=re.search(r'```(?:html)?\n([\s\S]*?)```',c); out=m.group(1) if m else c; fn='index.html'
else:
    m=re.search(r'<svg[\s\S]*?</svg>',c); out=m.group(0) if m else ''; fn='pelican.svg'
open(D+'/'+fn,'w').write(out)
print('usage',u,'reasoning_chars',len(r),'content_chars',len(c),'artifact_found',bool(m))
PY
BIN=~/.cache/ms-playwright/chromium_headless_shell-1248/chrome-headless-shell-linux64/chrome-headless-shell
F=$D/index.html; [ $T = pelican ] && F=$D/pelican.svg
timeout 90 $BIN --no-sandbox --headless --use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader --window-size=1280,800 --virtual-time-budget=10000 --screenshot=$D/shot.png file://$F 2>&1 | grep CONSOLE
echo "$T-$E DONE"
