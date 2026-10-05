"""Iter 3: station signs back to the Higgsfield s3 art; order sign = final drink (a bit lower) + recipe as colour dots
in the station-sign colours. -> production/qa/evidence/ui-s5-mockup-{phone,desktop}.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock5.py').read(); src=src[:src.rindex('COL=[')]
exec(compile(src,'mock5','exec'))
m4=open(S+'/ui/mock4.py').read()
exec(compile(m4[m4.index('def base3():'):m4.index('# ---- top bar')],'mock4.base3','exec'))   # Higgsfield station signs
def dot(col,n=12):
    im=Image.new('RGBA',(n,n),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse((0,0,n-1,n-1),fill=(43,29,26,255)); d.ellipse((1,1,n-2,n-2),fill=col+(255,))
    hi=tuple(min(255,int(c*1.15+30)) for c in col); d.arc((2,2,n-3,n-3),200,290,fill=hi+(255,),width=2)
    return im
RECIPE_ORDER=['cup','leaf_black','leaf_green','iced_tea','water_100','water_80','lemon']
def sign_icons(b,q):
    dr=up(L4('drink_'+drink_of(q['steps'])),dp(1))
    pr=str(q['price']); fnt=F(dp(26)); dd=ImageDraw.Draw(b)
    tw=dd.textlength(pr,font=fnt); total=dr.width+dp(3)+tw; x0=int((b.width-total)/2); y0=dp(15)
    b.alpha_composite(dr,(x0,y0))
    dd.text((x0+dr.width+dp(3),y0+dr.height//2+dp(1)),pr,font=fnt,fill=INK,anchor='lm')
    steps=['cup']+[s_ for s_ in RECIPE_ORDER if s_ in q['steps']]
    ds=[up(dot(mock.STEP_COL[s_]),dp(1)) for s_ in steps]; gap=dp(3)
    rw=sum(i.width for i in ds)+gap*(len(ds)-1); x=(b.width-rw)//2; yb=b.height-dp(12)
    for i in ds: b.alpha_composite(i,(x,yb-i.height)); x+=i.width+gap
COL=[(170,700),(196,730),(166,760),(192,790)]
for kind in ('phone','desktop'):
    setup(kind)
    need=dp(60+30+BH+28); SHIFT=max(0,need-kitchen_top())
    if SHIFT:
        for n_ in mock.MASKS: mock.MASKS[n_]=np.vstack([np.zeros((SHIFT,mock.MASKS[n_].shape[1]),np.uint8),mock.MASKS[n_][:-SHIFT]])
    print(kind,'shift dp',SHIFT/sc)
    f=base3()
    bx,bw,bh=bar_hud(f); ropes_signs(f,bx,bw,bh); hud_on_bar(f,bx,bw)
    f.convert('RGB').save(R+f'/production/qa/evidence/ui-s5-mockup-{kind}.jpg',quality=92)
    if kind=='phone':
        f.convert('RGB').crop((0,170,720,350)).resize((1440,360),Image.NEAREST).save(R+'/production/qa/evidence/ui-s5-orders-zoom.jpg',quality=92)
