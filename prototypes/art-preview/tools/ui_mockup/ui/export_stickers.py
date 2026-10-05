"""Export mock12 recipe stickers at art resolution (14x14, before upscale/tilt) -> art/ui_s7/sticker_<step>.png."""
import sys
from PIL import Image, ImageDraw
sys.argv=['x',sys.argv[1]]; sys.path.insert(0,sys.argv[1]+'/ui')
import mock
OUT=sys.argv[0] and '/Users/kpkr/WebstormProjects/tea-game/prototypes/art-preview/art/ui_s7/'
n=14
for step,col in mock.STEP_COL.items():
    im=Image.new('RGBA',(n,n),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.rounded_rectangle((0,0,n-1,n-1),radius=3,fill=(43,29,26,255))
    face=col if sum(col)<700 else (236,226,204)
    d.rounded_rectangle((1,1,n-2,n-2),radius=2,fill=face+(255,))
    hi=tuple(min(255,int(c*1.2+40)) for c in face); lo=tuple(int(c*0.82) for c in face)
    d.line((2,n-3,n-5,n-3),fill=lo+(255,)); d.line((n-3,2,n-3,n-6),fill=lo+(255,))
    d.line((2,2,2,6),fill=hi+(255,)); d.line((3,2,5,2),fill=hi+(255,))
    for y in range(n-4,n):
        for x in range(n-4,n):
            if x+y>=2*n-6: im.putpixel((x,y),(0,0,0,0))
    for p_ in [(n-5,n-3),(n-4,n-3),(n-5,n-2),(n-3,n-4),(n-3,n-5),(n-4,n-4)]: im.putpixel(p_,(214,204,184,255))
    for p_ in [(n-6,n-2),(n-6,n-1),(n-5,n-1),(n-4,n-2),(n-3,n-3),(n-2,n-4),(n-1,n-5),(n-1,n-6),(n-2,n-6)]: im.putpixel(p_,(43,29,26,255))
    im.save(OUT+f'sticker_{step}.png')
print('ok')
