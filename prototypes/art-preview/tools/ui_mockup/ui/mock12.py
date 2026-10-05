"""s7e: wider gaps between order plaques; recipe = real stickers (die-cut label, white border, tilt, peeled corner);
top bar content evenly spaced and vertically centred between the bar caps. -> ui-s7e-*.jpg"""
import sys, math
S=sys.argv[1]
src=open(S+'/ui/mock11.py').read(); src=src[:src.rindex("E=R+'/production")]
exec(compile(src,'mock11','exec'))
GAP=10                       # dp between hanging plaques
PW=74; STK=14; CP_GAP=5      # CP_GAP: dp between the cup and the price
CAP_SRC=120                  # bar art: end cap (nails) width, source px
BAR_MID_Y=118/245            # bar art: vertical centre of the planks
BAR_INNER_BOTTOM=229/245     # bar art: last plank row above the bottom outline
BAR_H=68                     # dp, visible bar height
PLQ_ICON_R=(135+10)/769      # score plaque art: right edge of star/coin icons (+outline), fraction of width
# ---------- stickers
def sticker(col,k):
    """Pixel sticker (art px): label in the step colour, Ink outline (no white border), gloss stripe,
    peeled corner showing the paper back; upscaled and tilted like it was slapped on by hand."""
    n=STK; im=Image.new('RGBA',(n,n),(0,0,0,0)); d=ImageDraw.Draw(im)
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
    big=up(im,dp(1))
    ang=(-10,7,-5,11,-8)[k%5]
    return big.rotate(ang,resample=Image.NEAREST,expand=True)
def _stickers_onto(out,steps,w,h):
    ds=[sticker(mock.STEP_COL[s_],i) for i,s_ in enumerate(steps)]; gap=-dp(1)
    rw=sum(i.width for i in ds)+gap*(len(ds)-1); x=int(w/2-rw/2)
    for i,dsi in enumerate(ds):
        sh=Image.new('RGBA',dsi.size,(0,0,0,0)); a=np.array(dsi); m=a[...,3]>0; s_=np.zeros_like(a); s_[m]=(20,12,8,90)
        y=h-dp(3)-dsi.height//2+(dp(1) if i%2 else 0)
        out.alpha_composite(Image.fromarray(s_),(x+dp(1),y+dp(1))); out.alpha_composite(dsi,(x,y)); x+=dsi.width+gap
_plaque_img=plaque_img
def plaque_img(q,wdp=None,hdp=None):
    # build the plaque without its dot stickers, then add real stickers
    global sticker_old
    q2=dict(q); steps=['cup']+[s_ for s_ in RECIPE_ORDER if s_ in q['steps']]
    fin,oy,ropes=_plaque_img_nodots(q2)
    w=fin.width; h=oy+dp(PH); _stickers_onto(fin,steps,w,h)
    return fin,oy,ropes
src11=open(S+'/ui/mock11.py').read()
body=src11[src11.index('def plaque_img('):src11.index("E=R+'/production",src11.index('def plaque_img('))]
body=body.replace('def plaque_img(','def _plaque_img_nodots(').replace('tot=dr.width+dp(1)+tw','tot=dr.width+dp(CP_GAP)+tw').replace('x0+dr.width+dp(1)','x0+dr.width+dp(CP_GAP)')
body='\n'.join(l for l in body.split('\n') if 'sticker(' not in l and 'ds[0]' not in l and 'enumerate(ds)' not in l)
exec(compile(body,'mock11.plaque','exec'))
def ropes_signs(f,bx,bw,bh):
    n=len(QUEUE); sw=PW; total=n*sw+(n-1)*GAP; x0=bx+(bw-total)/2
    rope=L6('rope'+VAR['plaque']); M=PLQ[VAR['plaque']]; s=dp(sw)/M['W']; rp=rescale(rope,s)
    for i,q in enumerate(QUEUE):
        im,oy,rx=plaque_img(q); cx=x0+i*(sw+GAP)+sw/2; X=int(dp(cx)-im.width/2); Y=dp(bh+30)-oy+dp(4)
        for r in rx:
            y=dp(bh-6)
            while y<Y+4: f.alpha_composite(rp.crop((0,0,rp.width,min(rp.height,Y+4-y))),(int(X+r-rp.width/2),y)); y+=rp.height
        f.alpha_composite(im,(X,Y))
        if 0.25<q['pat']<=0.6: paste_c(f,fit(C['warn'],dp(18)),X+im.width-dp(3),Y+oy+dp(2))
        if q['pat']<=0.25: paste_c(f,fit(C['urgent'],dp(20)),X+im.width-dp(3),Y+oy+dp(2))
# ---------- top bar: caps outside the content, items evenly spaced, centred on the planks
HUD={}
def bar_hud(f):
    Wdp=f.width/sc; bh=BAR_H
    pl=fit(C['plaque'],dp(46)); hearts=[fit(C[n],dp(22)) for n in ('hf','hf','he')]
    hw=sum(h_.width for h_ in hearts)+dp(3)*2; btn=[fit(C[n],dp(40)) for n in ('pause','snd')]
    items=[pl,('hearts',hw),btn[0],btn[1]]
    content=pl.width+hw+btn[0].width+btn[1].width
    s=dp(bh)/(BAR.height*0.86); cap=round(CAP_SRC*s)
    min_gap=dp(8)
    if content+3*min_gap+2*dp(6)+2*cap<=f.width-dp(8):   # wide: whole bar visible, content between caps
        inner=content+3*dp(14)+2*dp(8); bwpx=inner+2*cap; bxpx=(f.width-bwpx)//2
    else:                                                  # phone: caps run off-screen
        bxpx=-cap+dp(2); bwpx=f.width+2*cap-dp(4); inner=bwpx-2*cap
    bar,off=wood_bar_art(bwpx,dp(bh)); f.alpha_composite(bar,(bxpx,-off))
    yc=int((BAR.height*s*BAR_INNER_BOTTOM-off)/2)   # centre of the VISIBLE planks (top edge is off-screen)
    gap=(inner-2*dp(8)-content)/3; x=bxpx+cap+dp(8)
    HUD.update(yc=yc,pl=pl,hearts=hearts,btn=btn,xs=[])
    for it in [pl,'hearts',btn[0],btn[1]]:
        w_=hw if it=='hearts' else it.width; HUD['xs'].append(int(x)); x+=w_+gap
    vis_l=max(0,bxpx+cap); vis_r=min(f.width,bxpx+bwpx-cap)
    return vis_l/sc,(vis_r-vis_l)/sc,bh
def hud_on_bar(f,bx,bw):
    d=ImageDraw.Draw(f); yc=HUD['yc']; xs=HUD['xs']
    pl=HUD['pl']; f.alpha_composite(pl,(xs[0],yc-pl.height//2)); ph_=pl.height; y=yc-ph_//2
    tx=xs[0]+int(pl.width*PLQ_ICON_R)+dp(4)          # measured: icons end at 18.9 % of the plaque
    d.text((tx,y+ph_*0.30),'848',font=F(dp(23)),fill=(23,112,95),anchor='lm')
    d.text((tx,y+ph_*0.72),'250/250',font=F(dp(19)),fill=(138,94,0),anchor='lm')
    x=xs[1]
    for h_ in HUD['hearts']: f.alpha_composite(h_,(x,yc-h_.height//2)); x+=h_.width+dp(3)
    for b_,x in zip(HUD['btn'],xs[2:]): f.alpha_composite(b_,(x,yc-b_.height//2))
E=R+'/production/qa/evidence/'
ph=render('phone','A','C','black_tea'); ph.save(E+'ui-s7i-mockup-phone.jpg',quality=92)
ph.crop((0,0,720,340)).resize((1440,680),Image.NEAREST).save(E+'ui-s7i-top-zoom.jpg',quality=92)
dk=render('desktop','A','C','black_tea'); dk.save(E+'ui-s7i-mockup-desktop.jpg',quality=92)
dk.crop((640,0,1920,420)).save(E+'ui-s7i-top-desktop-zoom.jpg',quality=92)
print('ok')
