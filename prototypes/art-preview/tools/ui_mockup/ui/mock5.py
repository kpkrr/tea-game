"""Session 8 iter 2 (no Higgsfield): orders show the FINAL drink (scene-style pixel icon) + price, recipe small below;
station signs = scene-pixel board with the scene prop icon. Run like mock4 -> production/qa/evidence/ui-s4-mockup-{phone,desktop}.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock4.py').read(); src=src[:src.rindex('COL=[')]
exec(compile(src,'mock4','exec'))
sys.path.insert(0,S+'/ui')
D4=R+'/prototypes/art-preview/art/ui_s4/'
def L4(n): return Image.open(D4+n+'.png').convert('RGBA')
def up(im,u): return im.resize((max(1,round(im.width*u)),max(1,round(im.height*u))),Image.NEAREST)
def drink_of(steps):
    if 'iced_tea' in steps: return 'cold_tea'
    base='black_tea' if 'leaf_black' in steps else 'green_tea'
    return base+('_lemon' if 'lemon' in steps else '')
ORDER=['leaf_black','leaf_green','water_100','water_80','lemon','iced_tea']
def recipe(steps): return [s_ for s_ in ORDER if s_ in steps]
BH=74
def sign_ticket(q,W=84,H=BH,legs=0,u=2):
    s=0.3*sc/2; w,h=dp(W),dp(H); b=nine(BOARD,w,h,80,s)
    a=np.array(b); yy,xx=np.mgrid[0:h,0:w]; d=np.minimum(np.minimum(xx,yy),np.minimum(w-1-xx,h-1-yy))
    band=(d>=round(BAND_IN*s))&(d<round(BAND_OUT*s))
    ang=(np.degrees(np.arctan2(xx-(w-1)/2,-(yy-(h-1)/2)))+360)%360
    on=ang>=360*(1-q['pat']); a[band&on,:3]=timer_col(q['pat']); a[band&~on,:3]=(92,70,60)
    return Image.fromarray(a)
def sign_icons(b,q):
    dr=L4('drink_'+drink_of(q['steps'])); dr=up(dr,dp(1))
    pr=str(q['price']); fnt=F(dp(26)); dd=ImageDraw.Draw(b)
    tw=dd.textlength(pr,font=fnt); total=dr.width+dp(3)+tw; x0=int((b.width-total)/2)
    b.alpha_composite(dr,(x0,dp(11)))
    dd.text((x0+dr.width+dp(3),dp(11)+dr.height//2+dp(1)),pr,font=fnt,fill=INK,anchor='lm')
    ics=[up(L4('step_'+s_),dp(1)) for s_ in recipe(q['steps'])]; gap=dp(2)
    rw=sum(i.width for i in ics)+gap*(len(ics)-1); x=(b.width-rw)//2; yb=b.height-dp(12)
    for ic in ics: b.alpha_composite(ic,(x,yb-ic.height)); x+=ic.width+gap
# ---- station signs: scene-pixel board (art px = 1 dp), face tinted with the step colour, scene prop icon
import icons_s4 as I4
SIGNICON={s_:I4.pixelize(I4.STEPS[s_],20) for s_ in mock.STEP_COL}
def sign_px(step,legs):
    ic=SIGNICON[step]; fw,fh=max(ic.width+6,24),ic.height+6; W,H=fw+6,fh+6
    INKc=(43,29,26,255); WOOD=(155,104,58,255); WHI=(196,140,84,255); WLO=(112,72,40,255)
    col=mock.STEP_COL[step]; face=tuple(int(c*0.55+v*0.45) for c,v in zip(col,(246,234,211)))+(255,)
    TH=H+legs; im=Image.new('RGBA',(W,TH+1),(0,0,0,0)); d=ImageDraw.Draw(im)
    for lx in (4,W-7):
        d.rectangle((lx,H-2,lx+2,TH),fill=INKc); d.line((lx+1,H-1,lx+1,TH-1),fill=WOOD)
    d.rectangle((0,0,W-1,H-1),fill=INKc); d.rectangle((1,1,W-2,H-2),fill=WOOD); d.line((1,1,W-2,1),fill=WHI); d.line((1,H-2,W-2,H-2),fill=WLO)
    d.rectangle((2,2,W-3,H-3),fill=INKc); d.rectangle((3,3,W-4,H-4),fill=face)
    im.putpixel((0,0),(0,0,0,0)); im.putpixel((W-1,0),(0,0,0,0))
    im.alpha_composite(ic,((W-ic.width)//2,(H-ic.height)//2))
    return im,H
def base3():
    f=shifted_frame(); later=[]
    u=dp(1)
    for sid,v in A['stations'].items():
        t=v['type']
        if t in ('slot','trash'): continue
        m=mock.MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2
        gap=dp(3); b=bot-dp(4)
        _,H=sign_px(t,0); legs=max(3,int((b-(top-gap))/u))
        sg,_=sign_px(t,legs); sg=up(sg,u)
        f.alpha_composite(sg,(int(cx-sg.width/2),int(b-sg.height+dp(1))))
        if t.startswith('water') and KETTLE_DEMO[t][0]==1:
            gg=rescale(GAUGE[1],dp(26)/GAUGE[1].width); later.append((gg,(int(cx-gg.width/2),int(top+(bot-top)*0.42))))
    srcim=np.array(shifted_frame())
    for n,m in mock.MASKS.items():
        if n=='barista': continue
        a=srcim.copy(); a[...,3]=m*255; f.alpha_composite(Image.fromarray(a))
    for im,xy in later: f.alpha_composite(im,xy)
    k=MAP[0]
    for q,(x,y) in sorted(zip(QUEUE,COL),key=lambda z:z[1][1]):
        sp=Image.open(ART+f"guest_{q['spr']}_0.png").convert('RGBA')
        if q.get('flip'): sp=sp.transpose(Image.FLIP_LEFT_RIGHT)
        X,Y=Pq(x,y); Y+=SHIFT; h=int(111*2*k*(1+(y-614)/600))
        sp=fit(sp,h); a=np.array(sp).astype(float); a[...,:3]*=(0.97,0.9,0.86); sp=Image.fromarray(a.clip(0,255).astype('uint8'))
        sw=int(46*2*k); sh=Image.new('RGBA',(sw,int(12*2*k)),(0,0,0,0)); ImageDraw.Draw(sh).ellipse((0,0,sh.width-1,sh.height-1),fill=(25,15,10,110))
        f.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)),(int(X-sw/2),int(Y-sh.height/2)))
        f.alpha_composite(sp,(int(X-sp.width/2),int(Y-sp.height+3*k)))
    return f
_old_rs=ropes_signs
COL=[(170,700),(196,730),(166,760),(192,790)]
for kind in ('phone','desktop'):
    setup(kind)
    need=dp(60+30+BH+28); SHIFT=max(0,need-kitchen_top())
    if SHIFT:
        for n_ in mock.MASKS: mock.MASKS[n_]=np.vstack([np.zeros((SHIFT,mock.MASKS[n_].shape[1]),np.uint8),mock.MASKS[n_][:-SHIFT]])
    print(kind,'shift dp',SHIFT/sc)
    f=base3()
    bx,bw,bh=bar_hud(f); ropes_signs(f,bx,bw,bh); hud_on_bar(f,bx,bw)
    f.convert('RGB').save(R+f'/production/qa/evidence/ui-s4-mockup-{kind}.jpg',quality=92)
