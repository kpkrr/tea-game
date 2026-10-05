"""s7c: desktop frame rendered by the game with `--shift-y=89` (real extended plate above, no smeared strip);
island signs (iced tea, lemon) sit low behind their item and layer correctly over the cups. -> ui-s7c-*.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock9.py').read(); src=src[:src.rindex("E=R+'/production")]
exec(compile(src,'mock9','exec'))
ISLAND=('iced_tea','lemon')
GAME_SHIFT_PX=178     # --shift-y=89 vp px, frame is 2x
_setup=setup
def setup(kind):
    global FR,A
    _setup(kind)
    if kind=='desktop':
        FR=U+'/noguests-1280x800-shift89.png'; A=json.load(open(U+'/noguests-1280x800-shift89.json'))
        A['barista']['hand'][1]-=89          # base3 adds SHIFT again
def shifted_frame():                          # the game already shifted the view: no smeared fill
    return Image.open(FR).convert('RGBA')
def base3():
    f=shifted_frame(); src_=np.array(f); later=[]
    def restore(names):
        for n in names:
            a=src_.copy(); a[...,3]=mock.MASKS[n]*255; f.alpha_composite(Image.fromarray(a))
    def place(t,island):
        m=mock.MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2; wpx=dp(SIGN_W)
        if island:      # low: board bottom hidden behind the upper part of the item
            sg,_=sign6(t,wpx,dp(3)); y=int(top+(bot-top)*0.35-sg.height)
        else:
            b=bot-dp(4); legs=max(dp(3),int(b-(top-dp(3)))); sg,_=sign6(t,wpx,legs); y=int(b-sg.height+dp(1))
        f.alpha_composite(sg,(int(cx-sg.width/2),y))
        if t.startswith('water') and KETTLE_DEMO[t][0]==1:
            gg=rescale(GAUGE[1],dp(26)/GAUGE[1].width); later.append((gg,(int(cx-gg.width/2),int(top+(bot-top)*0.42))))
    types=[v['type'] for v in A['stations'].values() if v['type'] not in ('slot','trash')]
    for t in types:
        if t not in ISLAND: place(t,False)
    restore([n for n in mock.MASKS if n not in ISLAND and n!='barista'])
    for t in types:
        if t in ISLAND: place(t,True)
    restore([n for n in mock.MASKS if n in ISLAND])
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
def render(kind,sign,plaque,held):
    global SHIFT,HELD
    VAR['sign']=sign; VAR['plaque']=plaque; HELD=held
    setup(kind)
    SHIFT=GAME_SHIFT_PX if kind=='desktop' else max(0,dp(60+34+PH+30)-kitchen_top())
    if SHIFT:
        for n_ in mock.MASKS: mock.MASKS[n_]=np.vstack([np.zeros((SHIFT,mock.MASKS[n_].shape[1]),np.uint8),mock.MASKS[n_][:-SHIFT]])
    f=base3(); bx,bw,bh=bar_hud(f); ropes_signs(f,bx,bw,bh); hud_on_bar(f,bx,bw); return f.convert('RGB')
E=R+'/production/qa/evidence/'
ph=render('phone','A','C','black_tea'); ph.save(E+'ui-s7c-mockup-phone.jpg',quality=92)
ph.crop((0,520,720,940)).resize((1440,840),Image.NEAREST).save(E+'ui-s7c-signs-zoom.jpg',quality=92)
render('desktop','A','C','black_tea').save(E+'ui-s7c-mockup-desktop.jpg',quality=92)
print('ok')
