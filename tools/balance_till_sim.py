import random, statistics as st
T={'s':6,'m':9.5,'c':11.5}; P={'s':2,'m':5,'c':7}
def prog(t): return min(t/180,1)**2
def run(k,g0,g1,onb_f,onb_d,seed,smart=True):
    r=random.Random(seed); t=0; slots=[]; lost=0; served=0; rev=0; nxt=0; busy_until=0; cur=None
    dt=0.1
    while lost<3 and t<900:
        # spawn
        if t>=nxt and len(slots)<4:
            p=prog(t)*0.4
            if t<onb_d: rec='s'
            else:
                x=r.random(); rec='c' if x<p else ('m' if x<p+(1-p)/2 else 's')
            pm=50-25*prog(t)
            slots.append([t,pm,rec]); 
            gpm=(g0+(g1-g0)*prog(t))*(onb_f if t<onb_d else 1)
            nxt=t+60/gpm
        # service
        if cur and t>=busy_until:
            served+=1; rev+=P[cur[2]]; cur=None
        if cur is None and slots:
            # pick least remaining patience that can finish
            slots.sort(key=lambda g:g[0]+g[1])
            for g in slots:
                if g[0]+g[1] > t+T[g[2]]*k or True:
                    cur=g; slots.remove(g); busy_until=t+T[g[2]]*k; break
        # walkouts
        for g in list(slots):
            if t>=g[0]+g[1]: slots.remove(g); lost+=1
        if cur and t>=cur[0]+cur[1] and False: pass
        t+=dt
    return t,served,rev
def stats(k,g0,g1,onb_f,onb_d):
    res=[run(k,g0,g1,onb_f,onb_d,s) for s in range(200)]
    d=st.mean(x[0] for x in res); sv=st.mean(x[1] for x in res); rv=st.mean(x[2] for x in res)
    return d,sv,rv
print("config k: dur_s served rev matches_to_fill(250) day_min(excl. menus)")
for name,cfg in [("OLD 7->18 onb .5/30",(7,18,.5,30)),("NEW 15->18 onb 1/15",(15,18,1,15)),("NEW end 22",(15,22,1,15))]:
    for k in (1.0,0.8,0.65,0.5):
        d,sv,rv=stats(k,*cfg)
        print(f"{name:22s} k={k:.2f}: {d:6.0f}s served={sv:5.1f} rev={rv:6.1f} fill={250/rv:4.1f} matches = {250/rv*d/60:5.1f} min")
