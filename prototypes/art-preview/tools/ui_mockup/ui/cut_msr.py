"""Cut MSR v1 props (cup, jars, lemon bowl, kettle) with GrabCut -> art/ui_s4/src_*.png."""
import cv2, numpy as np
from PIL import Image
R='/Users/kpkr/WebstormProjects/tea-game'; OUT=R+'/prototypes/art-preview/art/ui_s4/'
img=cv2.imread(R+'/art-source/msr/msr-v1-props-materials.png')
k=2752/2000
BOX={'cup':(78,236,372,478),'jar_black':(1050,245,1200,460),'jar_green':(1218,238,1378,462),
     'lemon_bowl':(1400,272,1635,460),'kettle':(775,140,960,312)}
for n,(x0,y0,x1,y1) in BOX.items():
    r=(int(x0*k),int(y0*k),int((x1-x0)*k),int((y1-y0)*k))
    m=np.zeros(img.shape[:2],np.uint8); bg=np.zeros((1,65)); fg=np.zeros((1,65))
    cv2.grabCut(img,m,r,bg,fg,10,cv2.GC_INIT_WITH_RECT)
    if n in ("jar_green",): m[int(250*k):int(300*k),int(1250*k):int(1345*k)]=cv2.GC_FGD; cv2.grabCut(img,m,None,bg,fg,5,cv2.GC_INIT_WITH_MASK)
    a=np.where((m==1)|(m==3),255,0).astype(np.uint8)
    a=cv2.morphologyEx(a,cv2.MORPH_OPEN,np.ones((5,5),np.uint8))
    n_,lab,st,_=cv2.connectedComponentsWithStats(a); big=1+np.argmax(st[1:,4]); a=np.where(lab==big,255,0).astype(np.uint8)
    rgba=cv2.cvtColor(img,cv2.COLOR_BGR2RGBA); rgba[...,3]=a
    im=Image.fromarray(rgba); im=im.crop(im.getbbox()); im.save(OUT+'src_'+n+'.png'); print(n,im.size)
