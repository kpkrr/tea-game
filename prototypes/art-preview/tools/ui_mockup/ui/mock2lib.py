import sys, math
sys.argv=['x',sys.argv[1]]; S=sys.argv[1]; sys.path.insert(0,S+'/ui')
import mock
from mock import C, F, fit, paste_c, ring, sign, hud, INK
from PIL import Image, ImageDraw, ImageFilter
import numpy as np, json
R='/Users/kpkr/WebstormProjects/tea-game'; U=S+'/ui'
FR=U+'/noguests-360x800-t52.png'; A=json.load(open(U+'/noguests-360x800-t52.json'))
sc=2.0; dp=lambda v:int(round(v*sc))
ART=R+'/prototypes/art-preview/art/'
RAIL_Y=722
QUEUE=[  # front (at the till) -> back
 {'spr':2,'steps':['leaf_black','water_100'],'price':5,'pat':0.38,'pos':(181,612)},
 {'spr':1,'steps':['leaf_black','water_100'],'price':5,'pat':0.68,'pos':(156,640)},
 {'spr':0,'steps':['iced_tea'],'price':2,'pat':0.84,'pos':(206,666)},
 {'spr':0,'steps':['leaf_green','lemon','water_80'],'price':7,'pat':1.0,'pos':(164,694),'flip':True},
]
KETTLE='sheet'
KETTLE_DEMO={'water_100':(2,1.0),'water_80':(1,0.55)}
def gauge(state,prog,w=22,u=3):
    """Pixel pill gauge (units): Ink outline, dark track; amber while brewing, palette red when ready."""
    W,H=w,6; im=Image.new('RGBA',(W,H),(0,0,0,0)); px=im.load()
    fill=(216,50,60) if state==2 else (242,182,50); hi=(242,107,107) if state==2 else (255,214,110)
    n=int(round((W-4)*(1.0 if state==2 else (prog if state==1 else 0))))
    for y in range(H):
        for x in range(W):
            if (x in (0,W-1)) and (y in (0,H-1)): continue
            if x in (0,W-1) or y in (0,H-1): px[x,y]=(43,29,26,255)
            elif x in (1,W-2) or y==H-2: px[x,y]=(43,29,26,255) if (x in (1,W-2) and y in (1,H-2)) else (60,44,38,255)
            else: px[x,y]=(hi if y==1 else fill)+(255,) if x-2<n else (60,44,38,255)
    return im.resize((W*u,H*u),Image.NEAREST)
def ready_bubble():
    b=fit(C['warn'],dp(30)); a=np.array(b); h,w=a.shape[:2]
    # wipe the "!" glyph: dark pixels well inside the bubble -> parchment
    yy,xx=np.mgrid[0:h,0:w]; inner=(xx>w*0.25)&(xx<w*0.75)&(yy>h*0.15)&(yy<h*0.65)
    dark=a[...,:3].sum(-1)<200; a[inner&dark]=(246,234,211,255); b=Image.fromarray(a)
    pf=fit(C['puff'],dp(17)); b.alpha_composite(pf,((w-pf.width)//2,int(h*0.38-pf.height/2)))
    return b
def base():
    f=Image.open(FR).convert('RGBA'); k=f.width/A['viewport'][0]; P=lambda p:(p[0]*k,p[1]*k)
    later=[]
    for sid,v in A['stations'].items():
        t=v['type']
        if t in ('slot','trash'): continue
        m=mock.MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2
        unit=3; gap=dp(3); b=bot-dp(4); legs=max(3,int((b-(top-gap))/unit)); sg=sign(t,unit,legs)
        f.alpha_composite(sg,(int(cx-sg.width/2),int(b-sg.height+dp(1))))
        if t.startswith('water'):
            st_=KETTLE_DEMO.get(t,(v['state'],v.get('progress',0)))
            if KETTLE=='sheet':
                gname='g1' if st_[0]==1 else ('g2' if st_[0]==2 else 'g0')
                gg=fit(C[gname],dp(13 if gname=='g2' else 10)); gy=int(top+(bot-top)*0.42)-(gg.height-dp(10))
                later.append((gg,(int(cx-gg.width/2),gy)))
            else:
                if st_[0]==2:
                    bb=ready_bubble(); later.append((bb,(int(cx-bb.width/2),int(top-bb.height+dp(6)))))
                else:
                    gg=fit(C['g1' if st_[0]==1 else 'g0'],dp(10)); later.append((gg,(int(cx-gg.width/2),int(top+(bot-top)*0.42))))
    src=np.array(Image.open(FR).convert('RGBA'))
    for n,m in mock.MASKS.items():
        if n=='barista': continue
        a=src.copy(); a[...,3]=m*255; f.alpha_composite(Image.fromarray(a))
    for im,xy in later: f.alpha_composite(im,xy)
    # guests: back first so the front one overlaps
    for q in sorted(QUEUE,key=lambda q:q['pos'][1]):
        sp=Image.open(ART+f"guest_{q['spr']}_0.png").convert('RGBA')
        if q.get('flip'): sp=sp.transpose(Image.FLIP_LEFT_RIGHT)
        x,y=q['pos']; h=dp(111*(1+(y-614)/600))
        sp=fit(sp,h); a=np.array(sp).astype(float); a[...,:3]*=(0.97,0.9,0.86); sp=Image.fromarray(a.clip(0,255).astype('uint8'))
        sh=Image.new('RGBA',(dp(46),dp(12)),(0,0,0,0)); ImageDraw.Draw(sh).ellipse((0,0,dp(46)-1,dp(12)-1),fill=(25,15,10,110))
        f.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)),(int(dp(x)-sh.width/2),int(dp(y)-sh.height/2)))
        f.alpha_composite(sp,(int(dp(x)-sp.width/2),int(dp(y)-sp.height+dp(3))))
    hud(f,dp); return f
def timer_frame(w,h,frac,band=3,u=2):
    """Pixel frame (units) around a w x h box: Ink outline + colour band draining clockwise from 12 o'clock."""
    stops=[(1.0,(108,194,74)),(0.6,(242,194,48)),(0.25,(240,120,106)),(0.0,(216,50,60))]
    for i in range(3):
        if stops[i+1][0]<=frac<=stops[i][0]:
            t=(frac-stops[i+1][0])/(stops[i][0]-stops[i+1][0]); col=tuple(int(stops[i+1][1][j]+(stops[i][1][j]-stops[i+1][1][j])*t) for j in range(3))
    W,H=w+2*(band+2),h+2*(band+2); im=Image.new('RGBA',(W,H),(0,0,0,0)); px=im.load(); cx,cy=(W-1)/2,(H-1)/2
    for y in range(H):
        for x in range(W):
            d=min(x,y,W-1-x,H-1-y)
            if (x in (0,W-1)) and (y in (0,H-1)): continue
            if d==0 or d==band+1: px[x,y]=(43,29,26,255)
            elif d<=band:
                ang=(math.degrees(math.atan2(x-cx,-(y-cy)))+360)%360
                px[x,y]=(*col,255) if ang>=360*(1-frac) else (92,70,60,255)
            else: px[x,y]=(246,234,211,255)
    return im.resize((W*u,H*u),Image.NEAREST)
def ticket_rail(q,w):
    tk=dp(18); n=len(q['steps']); inner_w=w//2-8; inner_h=24
    t=timer_frame(inner_w,inner_h,q['pat']); d=ImageDraw.Draw(t)
    x=dp(5)+dp(1); cy=t.height//2
    for s in q['steps']: t.alpha_composite(fit(C[s],tk),(x,cy-tk//2)); x+=tk+dp(1)
    d.text((t.width-dp(7),cy+dp(1)),str(q['price']),font=F(dp(22)),fill=INK,anchor='rm')
    return t
def band(f,top):
    ov=Image.new('RGBA',f.size,(0,0,0,0)); d=ImageDraw.Draw(ov)
    d.rectangle((0,top,f.width,f.height),fill=(43,29,26,150)); d.rectangle((0,top,f.width,top+1),fill=(43,29,26,230))
    f.alpha_composite(ov); return f
def rail(f):
    if BAND: band(f,dp(RAIL_Y-12))
    d=ImageDraw.Draw(f); y=dp(RAIL_Y); x0,x1=dp(6),f.width-dp(6)
    d.rectangle((x0,y,x1,y+dp(6)),fill=(43,29,26)); d.rectangle((x0+2,y+2,x1-2,y+dp(6)-3),fill=(155,104,58)); d.line((x0+2,y+2,x1-2,y+2),fill=(196,140,84),width=2)
    for bx in (x0+dp(4),x1-dp(8)): d.rectangle((bx,y-dp(3),bx+dp(4),y+dp(9)),fill=(43,29,26))
    cw=(x1-x0-dp(6))//4
    for i,q in enumerate(QUEUE):
        t=ticket_rail(q,cw); tx=x0+dp(2)+i*(cw+dp(2))+(cw-t.width)//2; ty=y+dp(8)
        f.alpha_composite(t,(tx,ty))
        px=tx+t.width//2; d.rectangle((px-dp(2),y-dp(2),px+dp(2),ty+dp(5)),fill=(43,29,26)); d.rectangle((px-dp(1),y-dp(1),px+dp(1),ty+dp(4)),fill=(196,140,84))
        if q['pat']<=0.6 and q['pat']>0.25: paste_c(f,fit(C['warn'],dp(14)),tx+t.width-dp(2),ty+dp(1))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(16)),tx+t.width-dp(2),ty+dp(1))
    return f
def portrait(spr,size,flip=False):
    sp=Image.open(ART+f"guest_{spr}_0.png").convert('RGBA')
    if flip: sp=sp.transpose(Image.FLIP_LEFT_RIGHT)
    bb=sp.getbbox(); w=bb[2]-bb[0]; head=sp.crop((bb[0],bb[1],bb[2],bb[1]+int(w*0.95)))
    head=head.resize((size,size),Image.LANCZOS); m=Image.new('L',(size,size),0); ImageDraw.Draw(m).ellipse((0,0,size-1,size-1),fill=255)
    bg=Image.new('RGBA',(size,size),(232,214,180,255)); bg.alpha_composite(head); bg.putalpha(m); return bg
def dock(f):
    d=ImageDraw.Draw(f); top=dp(718); x0,x1,y1=dp(4),f.width-dp(4),dp(796)
    d.rounded_rectangle((x0,top,x1,y1),radius=dp(6),fill=(43,29,26)); d.rounded_rectangle((x0+dp(2),top+dp(2),x1-dp(2),y1-dp(2)),radius=dp(5),fill=(155,104,58))
    cw=(x1-x0-dp(10))//4
    for i,q in enumerate(QUEUE):
        cx0=x0+dp(4)+i*(cw+dp(1)); cy0=top+dp(5); ch=y1-top-dp(10)
        d.rounded_rectangle((cx0,cy0,cx0+cw,cy0+ch),radius=dp(4),fill=(43,29,26)); d.rounded_rectangle((cx0+dp(1),cy0+dp(1),cx0+cw-dp(1),cy0+ch-dp(1)),radius=dp(3),fill=(246,234,211))
        rg=ring(q['pat'],dp(40)); f.alpha_composite(rg,(cx0+dp(3),cy0+dp(2)))
        f.alpha_composite(portrait(q['spr'],dp(23),q.get('flip')),(cx0+dp(3)+(rg.width-dp(23))//2,cy0+dp(2)+(rg.height-dp(23))//2))
        d.text((cx0+cw-dp(6),cy0+dp(22)),str(q['price']),font=F(dp(26)),fill=INK,anchor='rm')
        tk=dp(16); n=len(q['steps']); sx=cx0+(cw-n*tk-(n-1)*dp(1))//2
        for s in q['steps']: f.alpha_composite(fit(C[s],tk),(sx,cy0+ch-tk-dp(4))); sx+=tk+dp(1)
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(13)),cx0+dp(40),cy0+dp(6))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(15)),cx0+dp(40),cy0+dp(6))
    return f







def sign_ticket(q,W=84,H=50,legs=60,u=2):
    """Wooden order sign on two posts (units = dp): Ink outline, wood rim, timer band, parchment face."""
    stops=[(1.0,(108,194,74)),(0.6,(242,194,48)),(0.25,(240,120,106)),(0.0,(216,50,60))]
    fr=q['pat']
    for i in range(3):
        if stops[i+1][0]<=fr<=stops[i][0]:
            t=(fr-stops[i+1][0])/(stops[i][0]-stops[i+1][0]); col=tuple(int(stops[i+1][1][j]+(stops[i][1][j]-stops[i+1][1][j])*t) for j in range(3))
    TH=H+legs; im=Image.new('RGBA',(W,TH),(0,0,0,0)); px=im.load(); cx,cy=(W-1)/2,(H-1)/2
    INKc=(43,29,26,255); WOOD=(155,104,58,255); WHI=(196,140,84,255); WLO=(112,72,40,255)
    for lx in (12,W-17):
        for y in range(H-2,TH):
            for k in range(5): px[lx+k,y]=INKc if k in (0,4) else (WHI if k==1 else WOOD)
    for y in range(H):
        for x in range(W):
            d=min(x,y,W-1-x,H-1-y)
            if (x in (0,W-1)) and (y in (0,H-1)): continue
            if d==0: px[x,y]=INKc
            elif d<=3: px[x,y]=WHI if y<=3 and d==y else (WLO if H-1-y==d else WOOD)
            elif d==4 or d==8: px[x,y]=INKc
            elif d<=7:
                ang=(math.degrees(math.atan2(x-cx,-(y-cy)))+360)%360
                px[x,y]=(*col,255) if ang>=360*(1-fr) else (92,70,60,255)
            else: px[x,y]=(246,234,211,255)
    im=im.resize((int(round(W*u)),int(round(TH*u))),Image.NEAREST); d=ImageDraw.Draw(im)
    n=len(q['steps']); tk=dp(22); gap=dp(2); rw=n*tk+(n-1)*gap
    x=(im.width-rw)//2; ty=dp(11)
    for st in q['steps']: im.alpha_composite(fit(C[st],tk),(x,ty)); x+=tk+gap
    d.text((im.width//2,dp(44)),str(q['price']),font=F(dp(24)),fill=INK,anchor='mm')
    return im
def soft_bottom(f,h):
    blur=f.filter(ImageFilter.GaussianBlur(dp(1.6)))
    m=Image.new('L',f.size,0); md=ImageDraw.Draw(m)
    for y in range(h):
        md.line((0,f.height-h+y,f.width,f.height-h+y),fill=int(255*min(1,(y/h)*1.4)))
    f.paste(blur,(0,0),m); return f
def signs(f):
    soft_bottom(f,dp(110))
    xs=[48,136,224,312]; base_y=dp(800)
    for i,(q,cx) in enumerate(zip(QUEUE,xs)):
        legs=40+(i%2)*0
        t=sign_ticket(q,legs=legs); f.alpha_composite(t,(int(dp(cx)-t.width/2),base_y-dp(50+legs)+dp(28)))
        X=int(dp(cx)+t.width/2); Y=base_y-dp(50+legs)+dp(28)
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(16)),X-dp(4),Y+dp(2))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(18)),X-dp(4),Y+dp(2))
    return f

def hanging(q,rope=74,W=84,H=62,u=2):
    b=sign_ticket(q,W=W,H=H,legs=0,u=u)
    im=Image.new('RGBA',(b.width,b.height+rope*u),(0,0,0,0)); px=Image.new('RGBA',(W,rope),(0,0,0,0)); pp=px.load()
    for rx in (14,W-17):
        for y in range(rope):
            for k in range(4):
                c=(43,29,26,255) if k in (0,3) else ((214,178,112,255) if (y//3+k)%2 else (176,136,78,255))
                pp[rx+k,y]=c
    im.alpha_composite(px.resize((W*u,rope*u),Image.NEAREST),(0,0)); im.alpha_composite(b,(0,rope*u-dp(1)))
    # knot rings where the rope meets the board
    d=ImageDraw.Draw(im)
    for rx in (14,W-17):
        x=(rx+1.5)*u; y=rope*u
        d.ellipse((x-dp(3),y-dp(3),x+dp(3),y+dp(3)),fill=(43,29,26)); d.ellipse((x-dp(2),y-dp(2),x+dp(2),y+dp(2)),fill=(176,136,78))
    return im
def hang_all(f):
    xs=[48,136,224,312]; ropes=[70,70,70,70]
    for q,cx,r in zip(QUEUE,xs,ropes):
        t=hanging(q,rope=r); x=int(dp(cx)-t.width/2); f.alpha_composite(t,(x,0))
        X=x+t.width; Y=dp(r)
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(16)),X-dp(4),Y+dp(2))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(18)),X-dp(4),Y+dp(2))
    hud(f,dp)   # HUD stays on top of the ropes
    return f
