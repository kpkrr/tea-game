import sys
S=sys.argv[1]
src=open(S+'/ui/mock2lib.py').read()
exec(compile(src,'mock2lib','exec'))
import numpy as np, json, math
from PIL import Image, ImageDraw, ImageFilter
PH_MASKS=dict(mock.MASKS)
def setup(kind):
    global FR,A,sc,dp,MAP,KETTLE
    if kind=='phone':
        FR=U+'/noguests-360x800-t52.png'; A=json.load(open(U+'/noguests-360x800-t52.json')); sc=2.0; MAP=(1.0,0.0,0.0)
    else:
        FR=U+'/noguests-1280x800-t52.png'; A=json.load(open(U+'/noguests-1280x800-t52.json')); sc=2.5
        s_=1.0383; MAP=(s_*sc/2.0,324.3*sc,-177.6*sc)   # phone frame px -> desktop frame px
    dp=lambda v:int(round(v*sc))
    globals()['dp']=dp
    k,ox,oy=MAP; f=Image.open(FR); W,H=f.size
    for n,m in PH_MASKS.items():
        im=Image.fromarray((m*255).astype('uint8')).resize((int(round(720*k)),int(round(1600*k))),Image.NEAREST)
        cv=Image.new('L',(W,H),0); cv.paste(im,(int(round(ox)),int(round(oy)))); mock.MASKS[n]=(np.array(cv)>127).astype(np.uint8)
    KETTLE='bubble'
def Pq(x,y):  # phone dp -> frame px
    k,ox,oy=MAP; return (x*2*k+ox, y*2*k+oy)
def kitchen_top():
    t=[]
    for sid,v in A['stations'].items():
        if v['type'] in ('cup','leaf_green','leaf_black'):
            m=mock.MASKS[v['type']]; ys,_=np.where(m); t.append(ys.min()-dp(3)-16*max(2,int(round(1.5*sc))))
    return min(t)
SHIFT=0
def shifted_frame():
    f=Image.open(FR).convert('RGBA')
    if SHIFT<=0: return f
    out=Image.new('RGBA',f.size); out.paste(f,(0,SHIFT))
    ramp=int(SHIFT*1.6); H=SHIFT+ramp
    # strong blur of the frame's own top, stretched over the gap, fading into the sharp picture
    src=f.crop((0,0,f.width,H)).resize((f.width,H),Image.LANCZOS)
    fill=out.copy(); fill.paste(src.resize((f.width,H)),(0,0))
    blur=out.crop((0,0,f.width,H+ramp)).copy(); blur.paste(src,(0,0))
    blur=blur.filter(ImageFilter.GaussianBlur(dp(14)))
    m=Image.new('L',(f.width,H+ramp),0); md=ImageDraw.Draw(m)
    for y in range(H+ramp):
        a=255 if y<SHIFT else int(255*max(0,1-(y-SHIFT)/(ramp+ramp)))
        md.line((0,y,f.width,y),fill=a)
    out.paste(blur,(0,0),m)
    return out
def base3():
    f=shifted_frame(); later=[]
    for sid,v in A['stations'].items():
        t=v['type']
        if t in ('slot','trash'): continue
        m=mock.MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2
        unit=max(2,int(round(1.5*sc))); gap=dp(3); b=bot-dp(4); legs=max(3,int((b-(top-gap))/unit)); sg=sign(t,unit,legs)
        f.alpha_composite(sg,(int(cx-sg.width/2),int(b-sg.height+dp(1))))
        if t.startswith('water'):
            st_=KETTLE_DEMO[t]
            if st_[0]==2:
                bb=ready_bubble(); later.append((bb,(int(cx-bb.width/2),int(top-bb.height+dp(6)))))
            else:
                gg=fit(C['g1'],dp(10)); later.append((gg,(int(cx-gg.width/2),int(top+(bot-top)*0.42))))
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
def wood_bar(wu,hu,r=6):
    """Pixel plank bar, units=dp: flat top (off-screen edge), rounded bottom corners, Ink outline."""
    im=Image.new('RGBA',(wu,hu+3),(0,0,0,0)); px=im.load()
    INKc=(43,29,26,255); W1=(155,104,58,255); W2=(140,92,50,255); HI=(196,140,84,255); LO=(112,72,40,255)
    def inside(x,y,rr):
        if y<hu-rr: return 0<=x<wu
        cy=hu-rr-0.5
        for cx in (rr-0.5,wu-rr-0.5):
            if (x<rr and cx==rr-0.5) or (x>=wu-rr and cx==wu-rr-0.5):
                return (x-cx)**2+(y-cy)**2<=rr*rr
        return 0<=x<wu and y<hu
    for y in range(hu):
        for x in range(wu):
            if not inside(x,y,r): continue
            edge=not(inside(x-1,y,r) and inside(x+1,y,r) and inside(x,y+1,r))
            if edge: px[x,y]=INKc; continue
            band=(y//14)
            c=W1 if band%2==0 else W2
            if y%14==0 and y>0: c=LO
            elif y%14==1: c=HI
            if (x+band*37)%61==0 and y%14>2: c=LO
            if y>=hu-3: c=LO
            px[x,y]=c
    # drop shadow
    sh=Image.new('RGBA',im.size,(0,0,0,0)); sp=sh.load()
    for y in range(hu):
        for x in range(wu):
            if inside(x,y,r) and not inside(x,y-3,r) if y>=3 else False: pass
    out=Image.new('RGBA',(wu,hu+3),(0,0,0,0))
    a=np.array(im); m=a[...,3]>0; shadow=np.zeros_like(a); shadow[3:][m[:-3]]=(20,12,8,110)
    out=Image.fromarray(shadow); out.alpha_composite(im); return out
def bar_hud(f):
    dpF=dp; Wdp=f.width/sc
    pl=fit(C['plaque'],dp(50)); heart=fit(C['hf'],dp(24)); btn=fit(C['pause'],dp(44))
    content=pl.width/sc+8+3*(heart.width/sc+3)+10+2*(btn.width/sc)+6
    bw=min(Wdp-8,content+20); bx=(Wdp-bw)/2; bh=60
    bar=wood_bar(int(round(bw)),bh); bar=bar.resize((int(round(bar.width*sc)),int(round(bar.height*sc))),Image.NEAREST)
    f.alpha_composite(bar,(int(bx*sc),0))
    return bx,bw,bh
def hud_on_bar(f,bx,bw):
    d=ImageDraw.Draw(f); x=dp(bx+10); y=dp(5)
    pl=fit(C['plaque'],dp(50)); f.alpha_composite(pl,(x,y)); ph=pl.height
    d.text((x+dp(26),y+ph*0.31),'848',font=F(dp(25)),fill=(23,112,95),anchor='lm')
    d.text((x+dp(26),y+ph*0.70),'250/250',font=F(dp(21)),fill=(138,94,0),anchor='lm')
    x2=x+pl.width+dp(8)
    for n in ('hf','hf','he'):
        s_=fit(C[n],dp(24)); f.alpha_composite(s_,(x2,y+dp(14))); x2+=s_.width+dp(3)
    rx=dp(bx+bw-10)
    for n in ('snd','pause'):
        s_=fit(C[n],dp(44)); rx-=s_.width; f.alpha_composite(s_,(rx,y+dp(2))); rx-=dp(6)
def ropes_signs(f,bx,bw,bh):
    rope=30; n=len(QUEUE); gapdp=4; sw=84
    total=n*sw+(n-1)*gapdp; x0=bx+(bw-total)/2
    for i,q in enumerate(QUEUE):
        u=sc; b=sign_ticket(q,W=84,H=62,legs=0,u=u)
        cx=x0+i*(sw+gapdp)+sw/2; X=int(dp(cx)-b.width/2); Y=dp(bh+rope)
        d=ImageDraw.Draw(f)
        for rx in (14,84-17):
            rxp=X+int(rx*u)
            for yy in range(dp(bh-4),Y+dp(2),max(1,int(u))):
                seg=((yy//int(3*u))%2)
                d.rectangle((rxp,yy,rxp+int(4*u)-1,yy+int(u)-1),fill=(43,29,26))
                d.rectangle((rxp+int(u),yy,rxp+int(3*u)-1,yy+int(u)-1),fill=(214,178,112) if seg else (176,136,78))
            for ky,kr in ((dp(bh-3),3),(Y,3)):
                kx=rxp+int(2*u); d.ellipse((kx-dp(kr),ky-dp(kr),kx+dp(kr),ky+dp(kr)),fill=(43,29,26)); d.ellipse((kx-dp(kr-1),ky-dp(kr-1),kx+dp(kr-1),ky+dp(kr-1)),fill=(176,136,78))
        f.alpha_composite(b,(X,Y))
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(16)),X+b.width-dp(4),Y+dp(2))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(18)),X+b.width-dp(4),Y+dp(2))
COL=[(170,700),(196,730),(166,760),(192,790)]
for kind in ('phone','desktop'):
    setup(kind)
    need=dp(60+30+62+32); SHIFT=max(0,need-kitchen_top())
    if SHIFT:
        for n in mock.MASKS: mock.MASKS[n]=np.vstack([np.zeros((SHIFT,mock.MASKS[n].shape[1]),np.uint8),mock.MASKS[n][:-SHIFT]])
    print(kind,'shift px',SHIFT,'= dp',SHIFT/sc)
    f=base3()
    bx,bw,bh=bar_hud(f); ropes_signs(f,bx,bw,bh); hud_on_bar(f,bx,bw)
    f.convert('RGB').save(R+f'/production/qa/evidence/ui-topbar-{kind}.jpg',quality=92)
