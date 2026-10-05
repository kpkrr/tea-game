"""Iter s6 (Higgsfield sheets ef090a85 / 4b7ea211 / d5912775): scene-style cups, station signs A/B, order plaques A/B/C.
-> production/qa/evidence/ui-s6-*.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock6.py').read(); src=src[:src.rindex('COL=[')]
exec(compile(src,'mock6','exec'))
D6=R+'/prototypes/art-preview/art/ui_s6/'
def L6(n): return Image.open(D6+n+'.png').convert('RGBA')
CUP={n:L6('cup_'+n) for n in ['empty','leaf_black','leaf_green','black_tea','green_tea','black_tea_lemon','green_tea_lemon','cold_tea','ruined']}
CUP_H=CUP['empty'].height
def cup_img(n,h_dp):
    s=dp(h_dp)/CUP_H; return rescale(CUP[n],s)
# ---------- station signs (Higgsfield s6), legs stretched
VAR={'sign':'A','plaque':'A'}
def sign6(step,width_px,legs_px):
    im=L6(f"sign{VAR['sign']}_{step}"); s=width_px/im.width; r=leg_row(im)
    board=rescale(im.crop((0,0,im.width,r)),s); leg=im.crop((0,r,im.width,im.height)).resize((board.width,max(2,legs_px)),Image.LANCZOS)
    out=Image.new('RGBA',(board.width,board.height+leg.height),(0,0,0,0)); out.alpha_composite(leg,(0,board.height)); out.alpha_composite(board,(0,0)); return out,board.height
def leg_row(im):
    a=np.array(im)[...,3]>0; w=a.sum(1); full=w.max()
    return int(np.where(w>0.75*full)[0].max())+1
HELD=None
def base3():
    f=shifted_frame(); later=[]
    for sid,v in A['stations'].items():
        t=v['type']
        if t in ('slot','trash'): continue
        m=mock.MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2
        gap=dp(3); b=bot-dp(4); wpx=dp(30)
        _,bh_=sign6(t,wpx,2); legs=max(dp(3),int(b-(top-gap)))
        sg,_=sign6(t,wpx,legs)
        f.alpha_composite(sg,(int(cx-sg.width/2),int(b-sg.height+dp(1))))
        if t.startswith('water') and KETTLE_DEMO[t][0]==1:
            gg=rescale(GAUGE[1],dp(26)/GAUGE[1].width); later.append((gg,(int(cx-gg.width/2),int(top+(bot-top)*0.42))))
    srcim=np.array(shifted_frame())
    for n,m in mock.MASKS.items():
        if n=='barista': continue
        a=srcim.copy(); a[...,3]=m*255; f.alpha_composite(Image.fromarray(a))
    for im,xy in later: f.alpha_composite(im,xy)
    if HELD:
        k_=f.width/A['viewport'][0]; hx,hy=A['barista']['hand']; c=cup_img(HELD,15)
        f.alpha_composite(c,(int(hx*k_-c.width*0.35),int(hy*k_+SHIFT-c.height*0.75)))
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
# ---------- order plaques
def measure(v):
    full=L6('plaque'+v); a=np.array(full).astype(int); H,W=a.shape[:2]; w=(a[...,3]>0).sum(1); top=int(np.argmax(w>0.85*W))
    lum=a[...,:3].sum(-1); my=(top+H)//2; mx=W//2
    def ins(seq):
        o=next(i for i in range(8,len(seq)) if seq[i]<200 and seq[i-1]>=200)
        n=next(i for i in range(o,len(seq)) if seq[i]>500); return o,n
    L_=ins(lum[my]); R_=ins(lum[my][::-1]); T_=ins(lum[top:,mx]); B_=ins(lum[::-1,mx])
    row=a[top-200,:,3]>0; xs=np.where(row)[0]; groups=np.split(xs,np.where(np.diff(xs)>3)[0]+1); ropes=[g.mean() for g in groups]
    return dict(full=full,top=top,L=L_,R=R_,T=T_,B=B_,ropes=ropes,W=W,H=H)
PLQ={v:measure(v) for v in 'ABC'}
def plaque_img(q,wdp=84,hdp=74):
    M=PLQ[VAR['plaque']]; s=dp(wdp)/M['W']; full=M['full']; top=M['top']
    board=full.crop((0,top,M['W'],M['H'])); bh_src=M['H']-top; cut=max(M['T'][1],M['B'][1])+12
    w=dp(wdp); h=dp(hdp); tp=rescale(board.crop((0,0,M['W'],cut)),s); bt=rescale(board.crop((0,bh_src-cut,M['W'],bh_src)),s)
    mid=board.crop((0,cut,M['W'],bh_src-cut)).resize((w,max(1,h-tp.height-bt.height)),Image.LANCZOS)
    b=Image.new('RGBA',(w,h),(0,0,0,0)); b.alpha_composite(tp.resize((w,tp.height)),(0,0)); b.alpha_composite(mid,(0,tp.height)); b.alpha_composite(bt.resize((w,bt.height)),(0,h-bt.height))
    a=np.array(b); yy,xx=np.mgrid[0:h,0:w]
    def rect(i): return (xx>=M['L'][i]*s)&(xx<w-M['R'][i]*s)&(yy>=M['T'][i]*s)&(yy<h-M['B'][i]*s)
    band=rect(0)&~rect(1)
    ang=(np.degrees(np.arctan2(xx-(w-1)/2,-(yy-(h-1)/2)))+360)%360; on=band&(ang>=360*(1-q['pat']))
    col=np.array(timer_col(q['pat'])); a[on,:3]=col; inner_edge=on&~np.roll(rect(1)|~band,0)  # flat fill
    hi=on&(np.roll(~band,1,axis=0)); a[hi,:3]=np.minimum(255,col*1.18+20)
    b=Image.fromarray(a)
    # content: drink (lower than centre of the upper zone) + price, recipe dots at the bottom of the parchment
    il,ir,it,ib=M['L'][1]*s,w-M['R'][1]*s,M['T'][1]*s,h-M['B'][1]*s
    dr=cup_img(drink_of(q['steps']),25); dr=dr.crop((0,max(0,dr.height-dp(25)-dp(4)),dr.width,dr.height))
    pr=str(q['price']); fnt=F(dp(22)); dd=ImageDraw.Draw(b); tw=dd.textlength(pr,font=fnt)
    tot=dr.width+dp(2)+tw; x0=int((il+ir)/2-tot/2); yb=int(ib-dp(15))
    b.alpha_composite(dr,(x0,yb-dr.height)); dd.text((x0+dr.width+dp(2),yb-dp(12)),pr,font=fnt,fill=INK,anchor='lm')
    steps=['cup']+[s_ for s_ in RECIPE_ORDER if s_ in q['steps']]
    ds=[up(dot(mock.STEP_COL[s_],10),dp(1)) for s_ in steps]; gap=dp(2); rw=sum(i.width for i in ds)+gap*(len(ds)-1); x=int((il+ir)/2-rw/2)
    for i in ds: b.alpha_composite(i,(x,int(ib-dp(3)-i.height))); x+=i.width+gap
    # attachments (rope ends, knots, rings) from the sheet, above the board
    att=rescale(full.crop((0,top-200,M['W'],top+int(cut*0.5))),s)
    out=Image.new('RGBA',(w,h+att.height-int(cut*0.5*s)),(0,0,0,0)); oy=att.height-int(cut*0.5*s)
    out.alpha_composite(b,(0,oy)); out.alpha_composite(att.resize((w,att.height)),(0,0))
    return out,oy,[r*s for r in M['ropes']]
def ropes_signs(f,bx,bw,bh):
    n=len(QUEUE); gapdp=4; sw=84; total=n*sw+(n-1)*gapdp; x0=bx+(bw-total)/2
    rope=L6('rope'+VAR['plaque']); M=PLQ[VAR['plaque']]; s=dp(sw)/M['W']; rp=rescale(rope,s)
    for i,q in enumerate(QUEUE):
        im,oy,rx=plaque_img(q); cx=x0+i*(sw+gapdp)+sw/2; X=int(dp(cx)-im.width/2); Y=dp(bh+30)-oy+dp(4)
        for r in rx:
            y=dp(bh-6)
            while y<Y+4: f.alpha_composite(rp.crop((0,0,rp.width,min(rp.height,Y+4-y))),(int(X+r-rp.width/2),y)); y+=rp.height
        f.alpha_composite(im,(X,Y))
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(20)),X+im.width-dp(4),Y+oy+dp(2))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(22)),X+im.width-dp(4),Y+oy+dp(2))
COL=[(170,700),(196,730),(166,760),(192,790)]
def render(kind,sign,plaque,held):
    global SHIFT,HELD
    VAR['sign']=sign; VAR['plaque']=plaque; HELD=held
    setup(kind)
    need=dp(60+34+74+30); SHIFT=max(0,need-kitchen_top())
    if SHIFT:
        for n_ in mock.MASKS: mock.MASKS[n_]=np.vstack([np.zeros((SHIFT,mock.MASKS[n_].shape[1]),np.uint8),mock.MASKS[n_][:-SHIFT]])
    f=base3(); bx,bw,bh=bar_hud(f); ropes_signs(f,bx,bw,bh); hud_on_bar(f,bx,bw); return f.convert('RGB')
E=R+'/production/qa/evidence/'
phones=[render('phone',s_,p_,'black_tea') for s_,p_ in (('A','A'),('B','B'),('A','C'))]
W_,H_=phones[0].size; g=30; out=Image.new('RGB',(W_*3+g*2,H_),(40,30,26))
for i,p in enumerate(phones): out.paste(p,(i*(W_+g),0)); p.save(E+f'ui-s6-mockup-phone-{"ABC"[i]}.jpg',quality=92)
out.save(E+'ui-s6-phone-variants-ABC.jpg',quality=90)
z=Image.new('RGB',(1440,3*380),(40,30,26))
for i,p in enumerate(phones): z.paste(p.crop((0,150,720,340)).resize((1440,380),Image.NEAREST),(0,i*380))
z.save(E+'ui-s6-plaques-zoom-ABC.jpg',quality=92)
z=Image.new('RGB',(1440,2*800),(40,30,26))
for i,p in enumerate(phones[:2]): z.paste(p.crop((0,540,720,940)).resize((1440,800),Image.NEAREST),(0,i*800))
z.save(E+'ui-s6-signs-zoom-AB.jpg',quality=92)
render('desktop','A','A','black_tea').save(E+'ui-s6-mockup-desktop-A.jpg',quality=92)
# held-cup states next to the barista (phone A)
cells=[]
for n in CUP:
    p=render('phone','A','A',n); k_=2; hx,hy=A['barista']['hand']
    cells.append(p.crop((int(hx*k_-90),int(hy*k_-150),int(hx*k_+90),int(hy*k_+60))).resize((360,420),Image.NEAREST))
st=Image.new('RGB',(9*370,420),(40,30,26))
for i,c in enumerate(cells): st.paste(c,(i*370,0))
st.save(E+'ui-s6-held-cups.jpg',quality=90)
print('ok')
