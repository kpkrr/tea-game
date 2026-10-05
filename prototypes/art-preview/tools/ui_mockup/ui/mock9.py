"""Iter s7b: owner picks plaque C; station signs bigger, plaques smaller, patience band muted. -> ui-s7b-*.jpg"""
import sys
S=sys.argv[1]
src=open(S+'/ui/mock7.py').read(); src=src[:src.index("E=R+'/production")]
for a,b in (('wdp=84,hdp=74','wdp=PW,hdp=PH'),('sw=84','sw=PW'),('wpx=dp(30)','wpx=dp(SIGN_W)'),('need=dp(60+34+74+30)','need=dp(60+34+PH+30)'),
            ("cup_img(drink_of(q['steps']),25)","cup_img(drink_of(q['steps']),CUP_DP)"),("dp(25)-dp(4)","dp(CUP_DP)-dp(4)"),('fnt=F(dp(22))','fnt=F(dp(20))')):
    assert a in src,a; src=src.replace(a,b)
PW,PH,SIGN_W,CUP_DP=76,66,36,22
exec(compile(src,'mock7','exec'))
m8=open(S+'/ui/mock8.py').read(); i8=m8.index("D6=R+"); exec(compile(m8[i8:m8.index("E=R+",i8)],'mock8','exec'))
_tc=timer_col
MUTE=0.35   # blend toward the empty-channel brown
def timer_col(fr):
    c=_tc(fr); return tuple(int(v*(1-MUTE)+w*MUTE) for v,w in zip(c,(92,70,60)))
E=R+'/production/qa/evidence/'
ph=render('phone','A','C','black_tea'); ph.save(E+'ui-s7b-mockup-phone.jpg',quality=92)
ph.crop((0,150,720,330)).resize((1440,360),Image.NEAREST).save(E+'ui-s7b-plaques-zoom.jpg',quality=92)
ph.crop((0,520,720,940)).resize((1440,840),Image.NEAREST).save(E+'ui-s7b-signs-zoom.jpg',quality=92)
render('desktop','A','C','black_tea').save(E+'ui-s7b-mockup-desktop.jpg',quality=92)
print('ok')
