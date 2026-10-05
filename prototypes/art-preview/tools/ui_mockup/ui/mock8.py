"""Iter s7 (Higgsfield 55c6b1ee / 239220e1 / 3ed35b18): chunky bright pixel cups, square station signs, plaques A/B/C.
-> production/qa/evidence/ui-s7-*.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock7.py').read(); src=src[:src.index("E=R+'/production")]
exec(compile(src,'mock7','exec'))
D6=R+'/prototypes/art-preview/art/ui_s7/'
CUP={n:L6('cup_'+n) for n in CUP}; CUP_H=CUP['empty'].height
PLQ={v:measure(v) for v in 'ABC'}
def sign6(step,width_px,legs_px):
    im=L6(f"signA_{step}"); s=width_px/im.width; r=leg_row(im)
    board=im.crop((0,0,im.width,r)).resize((width_px,width_px),Image.LANCZOS)   # square board (sheet came out ~4:5)
    leg=im.crop((0,r,im.width,im.height)).resize((board.width,max(2,legs_px)),Image.LANCZOS)
    out=Image.new('RGBA',(board.width,board.height+leg.height),(0,0,0,0)); out.alpha_composite(leg,(0,board.height)); out.alpha_composite(board,(0,0)); return out,board.height
E=R+'/production/qa/evidence/'
phones=[render('phone','A',p_,'black_tea') for p_ in 'ABC']
W_,H_=phones[0].size; g=30; out=Image.new('RGB',(W_*3+g*2,H_),(40,30,26))
for i,p in enumerate(phones): out.paste(p,(i*(W_+g),0)); p.save(E+f'ui-s7-mockup-phone-{"ABC"[i]}.jpg',quality=92)
out.save(E+'ui-s7-phone-variants-ABC.jpg',quality=90)
z=Image.new('RGB',(1440,3*380),(40,30,26))
for i,p in enumerate(phones): z.paste(p.crop((0,150,720,340)).resize((1440,380),Image.NEAREST),(0,i*380))
z.save(E+'ui-s7-plaques-zoom-ABC.jpg',quality=92)
phones[0].crop((0,540,720,940)).resize((1440,800),Image.NEAREST).save(E+'ui-s7-signs-zoom.jpg',quality=92)
render('desktop','A','A','black_tea').save(E+'ui-s7-mockup-desktop-A.jpg',quality=92)
cells=[]
for n in CUP:
    p=render('phone','A','A',n); k_=2; hx,hy=A['barista']['hand']
    cells.append(p.crop((int(hx*k_-90),int(hy*k_-150),int(hx*k_+90),int(hy*k_+60))).resize((360,420),Image.NEAREST))
st=Image.new('RGB',(9*370,420),(40,30,26))
for i,c in enumerate(cells): st.paste(c,(i*370,0))
st.save(E+'ui-s7-held-cups.jpg',quality=90)
print('ok')
