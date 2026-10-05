"""s7d: narrow order plaque (cup + price inside), recipe colour dots stuck on the bottom rim like stickers.
-> ui-s7d-*.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock10.py').read(); src=src[:src.rindex("E=R+'/production")]
exec(compile(src,'mock10','exec'))
PW,PH,CUP_DP=60,56,22
def sticker(col,n=11):
    im=Image.new('RGBA',(n,n),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse((0,0,n-1,n-1),fill=(43,29,26,255)); d.ellipse((1,1,n-2,n-2),fill=(246,234,211,255))   # paper edge
    d.ellipse((2,2,n-3,n-3),fill=col+(255,))
    hi=tuple(min(255,int(c*1.15+30)) for c in col); d.point([(4,3),(3,4),(4,4)],fill=hi+(255,))
    return im
def plaque_img(q,wdp=None,hdp=None):
    wdp=wdp or PW; hdp=hdp or PH
    M=PLQ[VAR['plaque']]; s=dp(wdp)/M['W']; full=M['full']; top=M['top']
    board=full.crop((0,top,M['W'],M['H'])); bh_src=M['H']-top; cut=max(M['T'][1],M['B'][1])+12
    w=dp(wdp); h=dp(hdp); tp=rescale(board.crop((0,0,M['W'],cut)),s); bt=rescale(board.crop((0,bh_src-cut,M['W'],bh_src)),s)
    mid=board.crop((0,cut,M['W'],bh_src-cut)).resize((w,max(1,h-tp.height-bt.height)),Image.LANCZOS)
    b=Image.new('RGBA',(w,h),(0,0,0,0)); b.alpha_composite(tp.resize((w,tp.height)),(0,0)); b.alpha_composite(mid,(0,tp.height)); b.alpha_composite(bt.resize((w,bt.height)),(0,h-bt.height))
    a=np.array(b); yy,xx=np.mgrid[0:h,0:w]
    def rect(i): return (xx>=M['L'][i]*s)&(xx<w-M['R'][i]*s)&(yy>=M['T'][i]*s)&(yy<h-M['B'][i]*s)
    band=rect(0)&~rect(1)
    ang=(np.degrees(np.arctan2(xx-(w-1)/2,-(yy-(h-1)/2)))+360)%360; on=band&(ang>=360*(1-q['pat']))
    a[on,:3]=np.array(timer_col(q['pat'])); b=Image.fromarray(a)
    il,ir,it,ib=M['L'][1]*s,w-M['R'][1]*s,M['T'][1]*s,h-M['B'][1]*s
    dr=cup_img(drink_of(q['steps']),CUP_DP); dr=dr.crop((0,max(0,dr.height-dp(CUP_DP)-dp(3)),dr.width,dr.height))
    pr=str(q['price']); fnt=F(dp(18)); dd=ImageDraw.Draw(b); tw=dd.textlength(pr,font=fnt)
    tot=dr.width+dp(1)+tw; x0=int((il+ir)/2-tot/2); yc=int((it+ib)/2)
    b.alpha_composite(dr,(x0,yc-dr.height//2-dp(1))); dd.text((x0+dr.width+dp(1),yc+dp(1)),pr,font=fnt,fill=INK,anchor='lm')
    # recipe stickers on the bottom rim, slightly overhanging the edge
    steps=['cup']+[s_ for s_ in RECIPE_ORDER if s_ in q['steps']]
    ds=[up(sticker(mock.STEP_COL[s_]),dp(1)) for s_ in steps]; gap=dp(1); rw=sum(i.width for i in ds)+gap*(len(ds)-1)
    pad=dp(4); out=Image.new('RGBA',(w,h+pad),(0,0,0,0)); out.alpha_composite(b,(0,0))
    x=int(w/2-rw/2); y=h-dp(4)-ds[0].height//2
    for i,dsi in enumerate(ds): out.alpha_composite(dsi,(x,y+(dp(1) if i%2 else 0))); x+=dsi.width+gap
    att=rescale(full.crop((0,top-200,M['W'],top+int(cut*0.5))),s)
    fin=Image.new('RGBA',(w,out.height+att.height-int(cut*0.5*s)),(0,0,0,0)); oy=att.height-int(cut*0.5*s)
    fin.alpha_composite(out,(0,oy)); fin.alpha_composite(att.resize((w,att.height)),(0,0))
    return fin,oy,[r*s for r in M['ropes']]
E=R+'/production/qa/evidence/'
ph=render('phone','A','C','black_tea'); ph.save(E+'ui-s7d-mockup-phone.jpg',quality=92)
ph.crop((0,150,720,330)).resize((1440,360),Image.NEAREST).save(E+'ui-s7d-plaques-zoom.jpg',quality=92)
render('desktop','A','C','black_tea').save(E+'ui-s7d-mockup-desktop.jpg',quality=92)
print('ok')
