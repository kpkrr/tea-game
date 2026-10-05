"""Session 8: mock3 layout re-rendered with the s3 Higgsfield art (cut by cut_s3.py).
Run: python ui/mock4.py prototypes/art-preview/tools/ui_mockup  -> production/qa/evidence/ui-s3-mockup-{phone,desktop}.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock3.py').read(); src=src[:src.index('COL=[')]
exec(compile(src,'mock3','exec'))
import numpy as np, math
from PIL import Image, ImageDraw
A3=R+'/prototypes/art-preview/art/ui_s3/'
def L(n): return Image.open(A3+n+'.png').convert('RGBA')
STEPS=['cup','lemon','leaf_green','leaf_black','water_80','water_100','iced_tea']
for s_ in STEPS: C[s_]=L('icon_sm_'+s_)          # small icons replace the round tokens on tickets
C['warn']=L('bubble_warn'); C['urgent']=L('bubble_urgent')
GAUGE={0:L('gauge_empty'),1:L('gauge_half'),2:L('gauge_full')}
def rescale(im,s): return im.resize((max(1,round(im.width*s)),max(1,round(im.height*s))),Image.LANCZOS)
def nine(im,w,h,m,s):
    """9-slice: source margin m px (all sides), output w x h, margins scaled by s."""
    W,H=im.size; mm=max(1,round(m*s)); out=Image.new('RGBA',(w,h),(0,0,0,0))
    xs=[(0,m,0,mm),(m,W-m,mm,w-mm),(W-m,W,w-mm,w)]; ys=[(0,m,0,mm),(m,H-m,mm,h-mm),(H-m,H,h-mm,h)]
    for sy0,sy1,dy0,dy1 in ys:
        for sx0,sx1,dx0,dx1 in xs:
            if dx1>dx0 and dy1>dy0: out.alpha_composite(im.crop((sx0,sy0,sx1,sy1)).resize((dx1-dx0,dy1-dy0),Image.LANCZOS),(dx0,dy0))
    return out
# ---- station signs: fixed board + stretched legs
def leg_row(im):
    a=np.array(im)[...,3]>0; w=a.sum(1); full=w.max(); return int(np.where(w>0.6*full)[0].max())+1
SIGN={s_:L('station_sign_'+s_+('_v2' if s_=='leaf_black' else '')) for s_ in STEPS}
def sign(step,unit,legs=5):
    im=SIGN[step]; s=(22*unit)/im.width; r=leg_row(im)
    board=rescale(im.crop((0,0,im.width,r)),s); leg=im.crop((0,r,im.width,im.height))
    lh=max(2,legs*unit-0); leg=leg.resize((board.width,lh),Image.NEAREST)
    out=Image.new('RGBA',(board.width,board.height+lh),(0,0,0,0)); out.alpha_composite(leg,(0,board.height)); out.alpha_composite(board,(0,0))
    return out
# ---- kettle: brewing pill only, READY = in-game steam (no overlay)
def base3():
    f=shifted_frame(); later=[]
    for sid,v in A['stations'].items():
        t=v['type']
        if t in ('slot','trash'): continue
        m=mock.MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2
        unit=max(2,int(round(1.5*sc))); gap=dp(3); b=bot-dp(4); board_h=round(SIGN[t].width and leg_row(SIGN[t])*(22*unit)/SIGN[t].width)
        legs=max(3,int((b-(top-gap))/unit)); sg=sign(t,unit,legs)
        f.alpha_composite(sg,(int(cx-sg.width/2),int(b-sg.height+dp(1))))
        if t.startswith('water'):
            st_=KETTLE_DEMO[t]
            if st_[0]==1:
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
# ---- top bar: 3-slice of the painted bar, top edge pushed off-screen
BAR=L('hud_bar')
def wood_bar_art(wpx,hpx):
    s=hpx/(BAR.height*0.86); cap=125
    bar=nine_h(BAR,wpx,round(BAR.height*s),cap,s); return bar,round(BAR.height*s)-hpx
def nine_h(im,w,h,cap,s):
    c=max(1,round(cap*s)); out=Image.new('RGBA',(w,h),(0,0,0,0)); W=im.width
    out.alpha_composite(im.crop((0,0,cap,im.height)).resize((c,h),Image.LANCZOS),(0,0))
    mid=im.crop((cap,0,W-cap,im.height)).resize((max(1,round((W-2*cap)*s)),h),Image.LANCZOS)
    x=c
    while x<w-c: out.alpha_composite(mid.crop((0,0,min(mid.width,w-c-x),h)),(x,0)); x+=mid.width
    out.alpha_composite(im.crop((W-cap,0,W,im.height)).resize((c,h),Image.LANCZOS),(w-c,0)); return out
def bar_hud(f):
    Wdp=f.width/sc
    pl=fit(C['plaque'],dp(50)); heart=fit(C['hf'],dp(24)); btn=fit(C['pause'],dp(44))
    content=pl.width/sc+8+3*(heart.width/sc+3)+10+2*(btn.width/sc)+6
    bw=min(Wdp-8,content+24); bx=(Wdp-bw)/2; bh=60
    bar,off=wood_bar_art(dp(bw),dp(bh)); f.alpha_composite(bar,(dp(bx),-off))
    return bx,bw,bh
# ---- hanging order signs: 9-slice board + timer in the inner band + tiled ropes + ring knots
BOARD=L('order_sign_board'); RING=L('order_sign_ring'); ROPE=L('rope_tile')
BAND_IN,BAND_OUT=53,69     # source px: inner band between rim ink and parchment
def timer_col(fr):
    stops=[(1.0,(108,194,74)),(0.6,(242,194,48)),(0.25,(240,120,106)),(0.0,(216,50,60))]
    for i in range(3):
        if stops[i+1][0]<=fr<=stops[i][0]:
            t=(fr-stops[i+1][0])/(stops[i][0]-stops[i+1][0]); return tuple(int(stops[i+1][1][j]+(stops[i][1][j]-stops[i+1][1][j])*t) for j in range(3))
def sign_ticket(q,W=84,H=62,legs=0,u=2):
    s=0.3*sc/2; w,h=dp(W),dp(H); b=nine(BOARD,w,h,80,s)
    a=np.array(b); yy,xx=np.mgrid[0:h,0:w]; d=np.minimum(np.minimum(xx,yy),np.minimum(w-1-xx,h-1-yy))
    band=(d>=round(BAND_IN*s))&(d<round(BAND_OUT*s))
    ang=(np.degrees(np.arctan2(xx-(w-1)/2,-(yy-(h-1)/2)))+360)%360
    on=ang>=360*(1-q['pat']); col=timer_col(q['pat'])
    a[band&on,:3]=col; a[band&~on,:3]=(92,70,60); b=Image.fromarray(a); dr=ImageDraw.Draw(b)
    n=len(q['steps']); tk=dp(22); gap=dp(2); rw=n*tk+(n-1)*gap; x=(w-rw)//2
    for st in q['steps']: b.alpha_composite(fit(C[st],tk),(x,dp(11)))  ; x+=0
    x=(w-rw)//2
    for st in q['steps']:
        ic=fit(C[st],tk) if C[st].height>=C[st].width else rescale(C[st],tk/C[st].width)
        x+=0
    return b
def sign_icons(b,q):
    n=len(q['steps']); tk=dp(24); gap=dp(1)
    ics=[rescale(C[st],tk/max(C[st].size)) for st in q['steps']]; rw=sum(i.width for i in ics)+(n-1)*gap
    x=(b.width-rw)//2
    for ic in ics: b.alpha_composite(ic,(x,dp(9)+(tk-ic.height)//2)); x+=ic.width+gap
    ImageDraw.Draw(b).text((b.width//2,dp(44)),str(q['price']),font=F(dp(24)),fill=INK,anchor='mm')
def ropes_signs(f,bx,bw,bh):
    rope=30; n=len(QUEUE); gapdp=4; sw=84
    total=n*sw+(n-1)*gapdp; x0=bx+(bw-total)/2
    rs=dp(5)/ROPE.width; rp=rescale(ROPE,rs); rg=rescale(RING,dp(5)/ROPE.width*0.9)
    for i,q in enumerate(QUEUE):
        b=nine(BOARD,dp(84),dp(62),80,0.3*sc/2); b=sign_ticket(q); sign_icons(b,q)
        cx=x0+i*(sw+gapdp)+sw/2; X=int(dp(cx)-b.width/2); Y=dp(bh+rope)
        for rx in (dp(13),b.width-dp(13)):
            y=dp(bh-6)
            while y<Y: f.alpha_composite(rp.crop((0,0,rp.width,min(rp.height,Y-y))),(X+rx-rp.width//2,y)); y+=rp.height
        f.alpha_composite(b,(X,Y))
        for rx in (dp(13),b.width-dp(13)): f.alpha_composite(rg,(X+rx-rg.width//2,Y-int(rg.height*0.78)))
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(20)),X+b.width-dp(4),Y+dp(2))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(22)),X+b.width-dp(4),Y+dp(2))
COL=[(170,700),(196,730),(166,760),(192,790)]
for kind in ('phone','desktop'):
    setup(kind)
    need=dp(60+30+62+32); SHIFT=max(0,need-kitchen_top())
    if SHIFT:
        for n_ in mock.MASKS: mock.MASKS[n_]=np.vstack([np.zeros((SHIFT,mock.MASKS[n_].shape[1]),np.uint8),mock.MASKS[n_][:-SHIFT]])
    print(kind,'shift dp',SHIFT/sc)
    f=base3()
    bx,bw,bh=bar_hud(f); ropes_signs(f,bx,bw,bh); hud_on_bar(f,bx,bw)
    f.convert('RGB').save(R+f'/production/qa/evidence/ui-s3-mockup-{kind}.jpg',quality=92)
