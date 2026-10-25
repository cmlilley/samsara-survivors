GOD=false
-- samsara survivors: data-driven rewrite (entity modes, boss sequencer, event places)
fr=0
GN={"narak","vora","ferrox","aurel","kharun","lumara","the judge"}
FN={"soul mote","deva","virtuous human","animal","hungry ghost","hellborn","asura"}
FHP=split("80,70,90,100,65,130,120")
FSPD=split("1,1,1,1.1,1.25,.9,1.05")
FDMG=split("1,1.1,1,1,.9,1.2,1.3")
FH=split("0,200,4,2,8,10,204")
EN={"slime","rat","skeleton","soldier","guardian","wisp","ghost","imp","big slime","brute","turret"}
-- foe rows: hp,spd,dmg,ess, mode, a,b,c,d,e,pspd
-- modes: 1 pulse, 2 weave, 4 shooter, 5 melee, 6 phase
-- shooter a=proj b=cd c=pdmg d=band-in e=band-out; melee a=jab-dmg b=jab-cd
ETS={"6,.35,4,1,1","4,.8,3,1,2","8,.4,4,2,4,bone,2.2,5,62,48,1.7","40,.3,12,6,5,18,1.6","26,0,6,3,4,bolt,2.6,6,0,0,1.1","5,.5,6,3,6","7,.55,0,2,1","14,.45,4,4,4,poke,2.8,5,54,40,1.9","24,.3,6,3,1","220,.28,18,20,5,24,1.2","20,0,0,0,4,bolt,2,5,0,0,1.8"}
ET={} for i=1,11 do ET[i]=split(ETS[i]) end
FSN=split("32,66,33,38,40,39,34,35,32,38,13")
FSF=split("0,1,0,0,0,0,0,0,0,0,0")
FDS=split("0,0,0,200,0,4,1,2,0,8,1,10,0,204")
PT=split("2,3,7,8,6,4")
PKS={ess=125,lot=12,heart=28}
ADS={inn={0,42}}
-- boss patterns per god, split rows: mv,mind,cd, akind, params...
-- akind: 1 pend(p1: 2 dash/3 swipe, p2 delay, p3 dash-spd)
-- 3 fan(n,step,sp,dm) 4 zones(p1: 1 patches/2 beams)
-- 5 set(p1: 1 vac/2 kwaves)
BPS={".35,50,2.6,4,1",".22,46,3.5,5,1",".5,0,2.6,1,2,.6,4",".15,70,1,3,3,.1,2,7","0,0,2.4,5,2",".3,42,3.2,4,2",".45,30,0,0"}
BP={} for i=1,7 do BP[i]={split(BPS[i])} end
BSP=split("128,0,132,2,140,3,136,2,192,0,194,0,198,3")
JACT={bolt={0,0,1.4,3,5,.06,2,7},melee={0,0,1.8,1,3,.5}}
FDEF={face=.25,kx=0,ky=0,burn=0,jab=0,scale=0}
BDEF={tm=0,pat=1,pt=4,acd=1,tele=0,ptm=0,tur=false,wcd=0,dash=0,vac=0,ring=3,burn=0,waves=0}
UN={"melee","bolt","spread","damage","speed","max hp","armor","regen","crit","cooldown","magnet"}
UI=split("112,115,116,119,120,121,122,123,124,127,30")
UM=split("5,5,4,5,5,5,5,5,5,5,5")
PL={{x=96,y=400,c=3}}
-- utils
function cl(v,a,b) return mid(a,v,b) end
function dst(x1,y1,x2,y2) local dx,dy=x2-x1,y2-y1 return sqrt(dx*dx+dy*dy) end
function ang(x,y) return atan2(x,y) end
function adf(a,b) return abs(((a-b+.5)%1)-.5) end
function dp(t) return dst(px,py,t.x,t.y) end
function dd(a,b) return dst(a.x,a.y,b.x,b.y) end
function ap(t) return ang(px-t.x,py-t.y) end
function af(t) return ang(t.x-px,t.y-py) end
function ae(a,b) return ang(b.x-a.x,b.y-a.y) end
function sxy(n) return (n%16)*8,flr(n/16)*8 end
function ban(t) bantxt=t bant=3 end
function tfmt() local s=flr(tsec) return flr(s/60)..":"..(s%60<10 and "0" or "")..s%60 end
function box(x0,y0,x1,y1) rectfill(x0,y0,x1,y1,0) rect(x0,y0,x1,y1,5) end
function nearfoe(x,y,r,e1,e2,e3) local bt,bd=nil,r for e in all(foes) do if e.hp>0 and e~=e1 and e~=e2 then local d=dst(x,y,e.x,e.y) if d<bd then bt,bd=e,d end end end return bt,bd end
-- save
function crown(a) for i=1,6 do if (a[i]==0) return false end return true end

function flg(b) return flr(flags/b)%2==1 end
function setflg(b) if not flg(b) then flags+=b dset(0,flags) end end
function loadsave() cartdata(GOD and "samsara_god" or "samsara_v1") if dget(36)~=777 then for i=0,63 do dset(i,0) end dset(36,777) dset(32,100) end flags=dget(0) sun={} blood={} carry={} for i=1,6 do sun[i]=dget(i) blood[i]=dget(6+i) end for i=1,3 do carry[i]=dget(27+i) if carry[i]>#UI then carry[i]=0 end end bank=dget(31) lastk=dget(32)-100 lives=dget(35) end
-- stats
function halo() return form==2 end
function horns() return form==6 end
function xpneed(n) return 5+4*n+n*n end
function recalc() local bh=asc and 110 or FHP[form] local bd=asc and 1.2 or FDMG[form] maxhp=bh+bmax+12*U[6] hp=min(hp,maxhp) dmgs=bd*(1+.08*U[4]) if horns() then dmgs*=1.05 end spd=1.4*FSPD[form]*(1+.06*U[5])*(GOD and 1.5 or 1) pdmg=10*dmgs*(1+.15*U[1]) bdmg=7*dmgs*(1+.15*U[2])*(1+alt) rng=20+2*U[1] mag=10*(1+.3*U[11])*(form==5 and 2 or 1)*(GOD and 3 or 1) essm=form==5 and 1.2 or 1 armor=U[7] regen=(halo() and .5 or 0)+.4*U[8] critc=.08*U[9] end
function ladder(k) return k>=60 and 2 or k>=20 and 3 or k>=-19 and 4 or k>=-59 and 5 or 6 end
function kadd(v) karma=cl(karma+v,-100,100) end
function heal(v) hp=min(maxhp,hp+v) end
function gainxp(v) v*=essm ess+=flr(v) xp+=v while xp>=need do xp-=need lvl+=1 lvlq+=1 need=xpneed(lvl) end end
-- life setup
function startlife(a) asc=a foes,pp,ep,pk,zn,ac,B={},{},{},{},{},{},nil U={} for i=1,#UI do U[i]=0 end for i=1,3 do if carry[i]>0 then U[carry[i]]=1 end end lvl,xp,need,ess,kills,bmax,alt=1,0,xpneed(1),0,0,0,0 karma=0 hp,px,py,face,pinv,pcd,bcd,avt,tsec,df,lvlq=1,256,256,.25,0,0,0,0,0,0,0 E={} if asc then form=1 elseif bank==1 then form=7 bank=0 dset(31,0) elseif lives==0 then form=1 else form=ladder(flr(lastk)) end lives+=1 dset(35,lives) recalc() hp=maxhp spawnt,endt,markearned=1,0,0 rerolled=false marktxt,crownnote,endform="","","" nextinn,speedt,fedt,pacc,ascidx,ascnext=25,0,0,0,1,20 E.shr=true state="play" ban(asc and "ascension life" or FN[form]) music(asc and 3 or 1) end
-- drawing helpers
function shad(x,y,r) rectfill(x-r,y+6,x+r,y+8,1) end
function drw(n,x,y,w,h,m,f) local sx,sy=sxy(n) if m==0 then sspr(sx,sy,8,16,x-w/2,y-h/2,w/2,h) sspr(sx,sy,8,16,x,y-h/2,w/2,h,true) elseif m==1 then sspr(sx,sy,16,16,x-w/2,y-h/2,w,h,f) elseif m==2 then sspr(sx,sy,16,h,x-16,y-h/2,16,h) sspr(sx,sy,16,h,x,y-h/2,16,h,true) else sspr(sx,sy,16,16,x-16,y-16,16,16) sspr(sx,sy,16,16,x,y-16,16,16,true) sspr(sx,sy,16,16,x-16,y,16,16,false,true) sspr(sx,sy,16,16,x,y,16,16,true,true) end end
function drawform(f,x,y,fa,at,m,pv) local fx,fy=cos(fa),sin(fa) local ff=fx<0 local n=FDS[2*f] if m and f~=2 then y+=(fr%12<6 and 1 or 0) end if f==1 then n=fr%12<6 and 0 or 1 elseif f==2 then local wn=at>0 and 203 or 202 spr(wn,x-15,y-8,1,2) spr(wn,x+7,y-8,1,2,true) if at>0 then n=201 end elseif f==7 then n=at>.1 and 205 or at>0 and 206 or 204 end drw(n,x,y,16,16,FDS[2*f-1],ff) if f==4 and m and fr%16>=8 then local c1,c2=61,62 if ff then c1,c2=62,61 end spr(c1,x-8,y,1,1,ff) spr(c2,x,y,1,1,ff) end if f==3 then line(x+fx*5,y+3+fy*5,x+fx*14,y+2+fy*14,4) elseif f==6 then spr(6,at>0 and x+fx*10-8 or x+(ff and -16 or 4),at>0 and y+fy*10-8 or y-6,2,2,ff) end if pv and halo() then circ(x,y-3,10,10) end end


function addpick(k,x,y,v) add(pk,{k=k,x=cl(x,10,502),y=cl(y,10,502),v=v or 1,t=rnd(1)}) end
function spawnpos() local a=rnd(1) local r=95+rnd(55) return cl(px+cos(a)*r,10,502),cl(py+sin(a)*r,10,502) end
function spawnfoe(t,x,y,o) o=o or {} if not x then x,y=spawnpos() end local b=ET[t] local hp=(o.hp or b[1])*(1+.2*tmin) local e={} for k,v in pairs(FDEF) do e[k]=v end e.k=t e.x=x e.y=y e.hp=hp e.mh=hp e.dmg=b[3] e.ess=b[4] e.tm=rnd(1) e.acd=.5+rnd(1.5) e.side=rnd()<.5 and -1 or 1 e.scale=o.scale or (t==9 and 24 or 0) e.r=t==10 and 16 or (e.scale>0 and 12 or 8) local ss=e.scale>0 and e.scale or 16 e.w=(t==1 or t==2 or t==4 or t==7 or t==9 or t==10) and ss or 16 e.h=(t==4 or t==10) and ss or 16 add(foes,e) return e end
function rpick(t) return t[flr(rnd(#t))+1] end
function pickn(p,c) local o={} for i=1,c do local j=flr(rnd(#p))+1 add(o,p[j]) p[j]=p[#p] p[#p]=nil end return o end
function picktype() local m=tmin local o={1,2} for i=1,6 do if m>=i then add(o,PT[i]) end end if m>=3 and rnd()<.1 then return 9 end return rpick(o) end
function addep(x,y,a,sp,d,k) add(ep,{x=x,y=y,dx=cos(a)*sp,dy=sin(a)*sp,d=d,k=k,t=0,life=3}) end
function hurt(d,u) if GOD then return end if u then if hp>0 then hp-=d end return end if pinv>0 or hp<=0 then return end sfx(42) hp-=max(1,d-armor) pinv=.5 end
function dmgx(t,d,crit,kx,ky,src) if t.hp<=0 then return end if t.god==4 and t.shield then d*=.25 end if crit then d*=2 end if GOD then d*=15 end t.hp-=d if t.k then t.kx+=kx t.ky+=ky end if form==6 and (t.god or src==1) then t.burn=3 end if t.god and t.hp<=0 then killboss() end end
function killfoe(e) kills+=1 addpick("ess",e.x+rnd(9)-4,e.y+rnd(9)-4,e.ess) if e.k==9 then for i=1,2 do spawnfoe(2,e.x+rnd(13)-6,e.y+rnd(13)-6) end end if e.k==10 then pendingrival=true end end
function sweepfoes() for e in all(foes) do if e.hp<=0 then killfoe(e) del(foes,e) end end end
function killboss() sfx(43) addpick("heart",B.x,B.y) if B.judge then pendingfinal=true B=nil return end if asc then ascidx=B.god+1 B=nil return end endform=B.form markearned=0 if B.form=="feral" then marktxt="no mark: feral god" else local tr=B.form=="trial" local tb=tr and sun or blood local was=crown(tb) tb[B.god]=1 dset((tr and 0 or 6)+B.god,1) markearned=tr and 174 or 175 marktxt=(tr and "sun mark: " or "blood mark: ")..GN[B.god] if not tr then bank=1 dset(31,1) end if not was and crown(tb) then crownnote=tr and "crown of heaven earned" or "crown of hell earned" end end B=nil endt=1 end
-- combat
function nearT(x,y,r,ph) local bt,bd=nearfoe(x,y,r,nil,nil,ph) local bk=bt and "f" or nil if B then local d=dst(x,y,B.x,B.y) if d<bd then bk,bt,bd="b",B,d end end return bk,bt,bd end
function arhit(r,d,src) local kb=src==1 and 1.5 or 0 for e in all(foes) do if e.hp>0 and dp(e)-e.r<=r then local a=af(e) if adf(a,face)<=1/6 then dmgx(e,d,src==1 and rnd()<critc,cos(a)*kb,sin(a)*kb,src) end end end if B and dp(B)-16<=r and adf(af(B),face)<=1/6 then dmgx(B,d,src==1 and rnd()<critc,0,0,0) end end
function doswing(tg) face=af(tg) avt=.16 arhit(rng+3,pdmg,1) end
function firebolt(tg) local a=af(tg) local n=1+U[3] for i=1,n do local aa=a+(i-(n+1)/2)*.035 add(pp,{x=px,y=py,dx=cos(aa)*3.2,dy=sin(aa)*3.2,d=bdmg,life=.62}) end end
function attacks(dt) pcd-=dt bcd-=dt avt=max(0,avt-dt) local cdm=max(.45,.93^U[10]) if pcd<=0 then local bk,tg,d=nearT(px,py,9999,true) if tg then local ed=d-(bk=="b" and 16 or tg.r) if ed<=rng then doswing(tg) pcd=.55*cdm end end end if bcd<=0 then local bk,tg,d=nearT(px,py,9999,true) if tg and d<=112 then firebolt(tg) bcd=.9*cdm end end end
function updpp(dt) for p in all(pp) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=false if B and dd(p,B)<18 then dmgx(B,p.d,rnd()<critc,0,0,0) dead=true else local hit=nil for e in all(foes) do if e.hp>0 and dd(p,e)<e.r+2 then hit=e break end end if hit then dmgx(hit,p.d,rnd()<critc,0,0,1) dead=true end end if dead or p.life<=0 or p.x<0 or p.x>512 or p.y<0 or p.y>512 then del(pp,p) end end end
function updep(dt) for p in all(ep) do p.t+=dt p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=p.life<=0 or p.x<-8 or p.x>520 or p.y<-8 or p.y>520 if dp(p)<6 then hurt(p.d) dead=true end if dead then del(ep,p) end end end
-- enemies: one update, mode-dispatched from the ET row
function movefoe(e,tx,ty,sp) local d=dst(e.x,e.y,tx,ty) if d>1 then local a=ang(tx-e.x,ty-e.y) e.x+=cos(a)*sp*df e.y+=sin(a)*sp*df e.face=a end end
function updfoe(e,dt) e.tm+=dt if e.burn>0 then e.burn-=dt e.hp-=2*dt end e.x=cl(e.x+e.kx*df,8,504) e.y=cl(e.y+e.ky*df,8,504) e.kx*=.8 e.ky*=.8 local r=ET[e.k] local sp=r[2] local d=dp(e) e.acd-=dt local m=r[5] if m==1 then if e.tm%.8<.35 then movefoe(e,px,py,sp) end elseif m==2 then local a=ap(e) e.x+=(cos(a)*sp+cos(a+.25)*sp*.35)*df e.y+=(sin(a)*sp+sin(a+.25)*sp*.35)*df e.face=a elseif m==4 then if d>r[9] then if sp>0 then movefoe(e,px,py,sp) end elseif d<r[10] then movefoe(e,2*e.x-px,2*e.y-py,sp) end if e.acd<=0 and d<=88 then local a=ap(e) if e.k==5 then e.face=a end addep(e.x,e.y,a,r[11],r[8],r[6]) e.acd=r[7] end elseif m==5 then if d>19 then movefoe(e,px,py,sp) end e.jab=max(0,e.jab-dt) if d<=22 and e.acd<=0 then e.jab=.18 hurt(r[6]) e.acd=r[7] end elseif m==6 then movefoe(e,px,py,sp*(e.tm%2.4<1.2 and 1 or .3)) end end
-- bosses: pattern data + shared act helpers + one sequencer
function spawnboss(g,fm) local x=cl(px+(rnd()<.5 and -80 or 80),30,482) local y=cl(py+(rnd()<.5 and -60 or 60),30,482) B={} for k,v in pairs(BDEF) do B[k]=v end B.god=g B.form=fm B.b1=BSP[2*g-1] B.bm=BSP[2*g] B.o1=g==3 and 142 or (g==7 and 196 or 0) B.oy=-8 B.x=x B.y=y B.hp=fm=="feral" and 1200 or 1600 B.mh=B.hp if g==7 then B.hp=2000 B.mh=2000 B.judge=true B.mode=max(U[2],U[3])>=U[1] and "bolt" or "melee" end ban(GN[g].." ("..fm..")") music(3) end
function bossfire(a,sp,d,k) addep(B.x,B.y,a,sp,d,k or "ember") end
function radial(n,sp,dm,off) local ra=off or rnd(1) for i=0,n-1 do bossfire(ra+i/n,sp,dm) end end
function fan(a,n,st,sp,dm) for i=-(n-1)/2,(n-1)/2 do bossfire(a+i*st,sp,dm) end end

function addzn1(x,y,r,w,b,d) add(zn,{k=1,x=x,y=y,r=r,wn=w,b=b,d=d}) end
function doact(A,a) local ak=A[4] local p1,p2,p3,p4=A[5],A[6],A[7],A[8] if ak==1 then B.tele=p2 B.pend=p1 B.ptm=p2 if p1==2 then B.dsp=p3 end elseif ak==3 then fan(a,p1,p2,p3,p4) elseif ak==4 then if p1==1 then for i=1,3 do addzn1(cl(px+(i-2)*22+rnd(13)-6,14,498),cl(py+rnd(25)-12,14,498),14,.7,4,6) end else for i=-1,1 do add(zn,{k=2,x=cl(px+i*24,8,504),w=8,wn=.8,b=1.5}) end end elseif ak==5 then if p1==1 then B.vac=2 else B.waves=3 B.wcd=0 end end end
function updboss(dt) if not B then return end B.tm+=dt if B.burn>0 then B.burn-=dt B.hp-=2*dt if B.hp<=0 then killboss() return end end B.pt-=dt if B.pt<=0 then B.pat=B.pat%#BP[B.god]+1 B.pt=4 end B.tele=max(0,B.tele-dt) local d=dp(B) local a=ap(B) local sm=B.p2 and 1.4 or 1 local g=B.god local busy=false if g==2 and B.vac>0 then B.vac-=dt local va=af(B) px+=cos(va)*1.1*df py+=sin(va)*1.1*df busy=true if B.vac<=0 then fan(a,3,.12,2,7) for i=1,2 do spawnfoe(1,B.x+rnd(21)-10,B.y+rnd(21)-10) end end end if g==4 then B.shield=B.tm%10<6 B.o1=B.shield and 170 or 138 B.oy=B.shield and -14 or -16 if B.shield and not B.tur then B.tur=true for i=-1,1,2 do local te=spawnfoe(11,B.x+i*26,B.y+10) te.acd=rnd(1) end end if not B.shield then B.tur=false end end if g==5 then if d>60 and B.dash<=0 then movefoe(B,px,py,.25*sm) end if B.pat==1 and B.waves>0 and B.dash<=0 then B.wcd-=dt if B.wcd<=0 then fan(a,5,.06,2,7) B.waves-=1 B.wcd=.25 end end for i=0,2 do local sa=B.tm*.4+i/3 if dst(px,py,B.x+cos(sa)*20,B.y+sin(sa)*20)<7 then hurt(8) end end end if g==7 then if not B.p2 and B.hp<B.mh/2 then B.p2=true B.b1=228 B.o1=230 ban("the wheel breaks") end if B.p2 then B.ring-=dt if B.ring<=0 then radial(12,1.5,7,0) B.ring=3 end end end local P=BP[g][B.pat] if B.dash>0 then B.x+=B.dvx*df B.y+=B.dvy*df B.dash-=dt elseif not busy then local mv=P[1] if g==4 and not B.shield then mv=0 end if mv>0 and d>P[2] then movefoe(B,px,py,mv*sm) end end B.acd-=dt if B.acd<=0 and not busy then local A=P if g==7 then A=JACT[B.mode] end if g==4 and B.shield then A=nil end if g==5 and (B.dash>0 or (B.pat==1 and B.waves>0)) then A=nil end if A and A[4]>0 then doact(A,a) B.acd=A[3] end end if B.pend then B.ptm-=dt if B.ptm<=0 then local p=B.pend B.pend=nil if p==2 then local da=ap(B) B.dvx,B.dvy=cos(da)*B.dsp,sin(da)*B.dsp B.dash=.35 elseif p==3 then if d<48 then hurt(18) end end end end B.x=cl(B.x,16,496) B.y=cl(B.y,16,496) end


function spawnactor(k,x,y) local a={k=k,x=x,y=y,hp=1,inv=0,tm=0,life=20,feed=0,fa=0,wt=0,a=rnd(1),acd=0,dead=false} add(ac,a) return a end
function killactor(a,m) if a.dead then return end a.dead=true if a.k=="inn" then kadd(-3) ban(m or "an innocent has fallen -3") end end
function updactors(dt) for a in all(ac) do a.tm+=dt a.inv=max(0,a.inv-dt) if a.k=="inn" then local fe=nearfoe(a.x,a.y,26) if fe then local fa=ang(a.x-fe.x,a.y-fe.y) a.x+=cos(fa)*.9*df a.y+=sin(fa)*.9*df else a.x+=cos(a.a)*.45*df a.y+=sin(a.a)*.45*df end if a.x<6 or a.x>506 or a.y<6 or a.y>506 then a.dead=true kadd(3,false) ban("an innocent passed safely +3") end if not a.dead then for e in all(foes) do if e.hp>0 and dd(a,e)<9 then killactor(a) break end end end if not a.dead and dp(a)<14 and btnp(5) then killactor(a,"you slew an innocent -3") end end if a.dead then del(ac,a) end end end

function addupgrade(i) U[i]+=1 recalc() if i==6 then heal(12) end end

function placefx(chan) if chan then kadd(8,false) ban("prayer heard +8") else kadd(-8,true) local ow={} for i=1,#UI do if U[i]>0 and U[i]<UM[i] then add(ow,i) end end if #ow==0 then bmax+=12 recalc() heal(12) ban("+12 max hp") else addupgrade(rpick(ow)) ban("free upgrade") end ban("shrine smashed -8") end end
function places(dt) local P=PL[1] if E.shr and not E.shrdone then if dp(P)<20 then if btnp(5) then E.shrdone=true sfx(44) placefx(false) else E.ch1=(E.ch1 or 0)+dt heal(maxhp*.1*dt) if E.ch1>=P.c then E.shrdone=true sfx(44) placefx(true) end end else E.ch1=0 end end end
function dolock() lockform=karma>=30 and "trial" or (karma<=-30 and "war" or "feral") lockgod=1 for i=1,6 do local need=sun[i]==0 if lockform=="war" then need=blood[i]==0 elseif lockform=="feral" then need=need or blood[i]==0 end if need then lockgod=i break end end ban(lockform.." form: "..GN[lockgod]) for i=1,6 do spawnfoe(picktype()) end end
function ev(t,k) if tsec>=t and not E[k] then E[k]=true return true end end
function events(dt) if asc then if not B and ascidx<=6 and tsec>=ascnext then spawnboss(ascidx,"trial") ascnext+=35 elseif not B and ascidx>6 and not judgespawned and tsec>=215 then judgespawned=true spawnboss(7,"asc") end return end if ev(65,"gua") then spawnfoe(5,150,150) spawnfoe(5,362,330) end if ev(65,"shrw") then ban("the roadside shrine wakes") end if ev(130,"mini") then spawnfoe(10) ban("mini-boss: the brute") end if ev(250,"lock") then dolock() end if ev(265,"boss") then spawnboss(lockgod,lockform) end nextinn-=dt if nextinn<=0 then nextinn=42 local n=0 for a in all(ac) do if a.k=="inn" then n+=1 end end if n<2 then local e=flr(rnd(4)) local ix,iy,ia if e==0 then ix,iy,ia=8,20+rnd(472),0 elseif e==1 then ix,iy,ia=504,20+rnd(472),.5 elseif e==2 then ix,iy,ia=20+rnd(472),8,.25 else ix,iy,ia=20+rnd(472),504,.75 end local na=spawnactor("inn",ix,iy) na.a=ia end end end
function updpick(dt) for p in all(pk) do p.t+=dt local d=dp(p) if p.k=="ess" then if d<mag then local a=ap(p) p.x+=cos(a)*3.5*df p.y+=sin(a)*3.5*df end if d<7 then sfx(41) gainxp(p.v) fedt=0 del(pk,p) end elseif p.k=="lot" or p.k=="heart" then if d<9 then sfx(41) heal(p.k=="lot" and 15 or 25) del(pk,p) end elseif p.k=="chest" then if d<10 then del(pk,p) openchoices(3,"chest") return end end end end

function openchoices(n,src) sfx(40) local pool={} for i=1,#UI do if U[i]<UM[i] then add(pool,i) end end if #pool==0 then heal(25) ban("nothing left to learn: healed 25") state="play" return end ch=pickn(pool,min(n,#pool)) chsrc=src chn=n sel=1 state="level" srt=0 end
function navc(c,n) if btnp(0) or btnp(2) then c-=1 end if btnp(1) or btnp(3) then c+=1 end return c<1 and n or c>n and 1 or c end
function updchoice() srt+=1/60 sel=navc(sel,#ch) if btnp(4) or btnp(5) then local src=chsrc addupgrade(ch[sel]) if src=="level" and lvlq>0 then lvlq-=1 openchoices(form==3 and 4 or 3,"level") else state="play" end end end
function setmodal(t,l,o,cb,au) modal={t=t,l=l,o=o,cb=cb,auto=au or 1,sel=1} state="modal" srt=0 end
function docb(cb,s) if cb=="rival" then if s==1 then kadd(12) state="play" else kadd(-12) openchoices(3,"free") end elseif cb=="final" then if s==1 then setflg(1) state="rebirth" else setflg(2) state="ending" end end end
function updmodal() srt+=1/60 modal.sel=navc(modal.sel,#modal.o) if btnp(4) or btnp(5) then docb(modal.cb,modal.sel) end end
function entertally(r) if state=="tally" then return end carry={} for i=1,3 do local bi,bv=0,0 for j=1,#UI do if U[j]>bv then bi,bv=j,U[j] end end if bi==0 then break end carry[i]=bi dset(27+i,bi) U[bi]=0 end for i=#carry+1,3 do dset(27+i,0) end lastk=flr(karma) dset(32,lastk+100) state="tally" srt=0 end
function updtally() if btnp(4) then state="rebirth" music(0) end end
-- main update
function updateplay(dt) tsec+=dt tmin=flr(tsec/60) df=dt*60 bant=max(0,bant-dt) pinv-=dt speedt=max(0,speedt-dt) fedt+=dt local mx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0) local my=(btn(3) and 1 or 0)-(btn(2) and 1 or 0) pmove=0 mvflag=false if mx~=0 or my~=0 then local l=sqrt(mx*mx+my*my) face=ang(mx,my) local sp=spd*(speedt>0 and 1.4 or 1) px=cl(px+mx/l*sp*df,10,502) py=cl(py+my/l*sp*df,10,502) pmove=sp*df mvflag=true end events(dt) if state~="play" then return end places(dt) local cap=min(30,8+5*tmin) if not B and not asc then spawnt-=dt if spawnt<=0 and #foes<cap then spawnfoe(picktype()) spawnt=max(.25,1-.15*tmin) end end for e in all(foes) do if e.hp>0 then updfoe(e,dt) end end sweepfoes() updboss(dt) updactors(dt) attacks(dt) sweepfoes() updpp(dt) updep(dt) for z in all(zn) do if z.wn>0 then z.wn-=dt else z.b-=dt if z.k==1 then if dp(z)<z.r then pacc+=dt if pacc>=.5 then pacc=0 hurt(z.d*.5,true) end end elseif abs(px-z.x)<z.w then hurt(10*dt,true) end end if z.b<=0 then del(zn,z) end end updpick(dt) if state~="play" then return end for e in all(foes) do if e.hp>0 and dp(e)<e.r+6 then hurt(e.dmg) end end if B and dp(B)<22 then hurt(15) end if form==5 and fedt>5 and hp>maxhp*.3 then hp=max(maxhp*.3,hp-.5*dt) end if regen>0 then heal(regen*dt) end if hp<=0 then entertally("death") return end if endt>0 then endt-=dt if endt<=0 then entertally("boss") return end end if pendingrival then pendingrival=false setmodal("the rival soul",{"the brute falls. the rival's soul","hovers, waiting for your word.","mercy: +12 karma.","execute: -12 karma, steal an upgrade."},{"mercy","execute"},"rival",1) return end if pendingfinal then pendingfinal=false setmodal("the empty throne",{"the judge is defeated. the throne","sits empty, and the wheel is still.","sit: free play among the gods.","step off: the true ending."},{"sit on the throne","step off the wheel"},"final",1) return end if not asc and tsec>=300 then entertally("time") return end if lvlq>0 then lvlq-=1 openchoices(form==3 and 4 or 3,"level") end end
-- drawing
function drawworld() camx=cl(px-64,0,384) camy=cl(py-64,0,384) camera(camx,camy) cls(3) for gy=flr(camy/8),flr((camy+120)/8)+1 do for gx=flr(camx/8),flr((camx+120)/8)+1 do local h=(gx*73+gy*149)%89 if h<9 then pset(gx*8+h%6+1,gy*8+(h*3)%6+1,h<4 and 11 or 4) end end end rectfill(0,400,511,407,4) rect(1,1,510,510,5) drw(13,96,400,16,16,0) if E.shr and not E.shrdone then circ(96,400,20-((E.ch1 or 0)/3)*20,11) if dp(PL[1])<30 then print("stand: pray  x: smash",54,382,7) end end for z in all(zn) do if z.wn>0 then if z.k==1 then circ(z.x,z.y,z.r,8) else line(z.x,0,z.x,511,10) end elseif z.k==1 then circfill(z.x,z.y,z.r,8) else rectfill(z.x-z.w,0,z.x+z.w,511,10) end end for p in all(pk) do if p.k=="chest" then drw(232,p.x,p.y,16,16,0) else spr(PKS[p.k],p.x-4,p.y-4) end end for a in all(ac) do shad(a.x,a.y,5) local as=ADS[a.k] drw(as[2],a.x,a.y,16,16,as[1],cos(a.a)<0) if a.k=="inn" then circfill(a.x,a.y-11,2,10) if dp(a)<16 then print("x: slay",a.x-10,a.y-19,8) end end end for e in all(foes) do local k=e.k if k==11 then pal(5,9) pal(6,10) end drw(FSN[k],e.x,e.y,e.w,e.h,FSF[k],cos(e.face)<0) pal() if k==8 then spr(36,e.x-8,e.y-3,2,1) end end if B then local x,y=B.x,B.y shad(x,y,12) local g=B.god if B.bm==0 then spr(B.b1,x-8,y-16,2,4,g==5 and cos(B.tm*.3)<0,g==5 and sin(B.tm*.3)<0) else drw(B.b1,x,y,32,32,B.bm) end if g==1 and B.tele>0 then spr(130,x-16,y-16,1,4) spr(130,x+8,y-16,1,4,true) end if g==2 and B.vac>0 then drw(134,x,y+2,32,16,2) end if B.o1>0 then spr(B.o1,x-8,y+B.oy,2,2) end if g==5 then for i=0,2 do local sa=B.tm*.4+i/3 circfill(x+cos(sa)*20,y+sin(sa)*20,1,7) end end end shad(px,py,6) if not (pinv>0 and fr%4<2) then drawform(form,px,py,face,avt,mvflag,true) end if avt>0 then local fx,fy=cos(face),sin(face) spr(5,px+fx*16-4,py+fy*16-4,1,1,fx<0,fy<0) end for p in all(pp) do circfill(p.x,p.y,2,12) end for p in all(ep) do if p.k=="bone" then spr(52,p.x-4,p.y-4) elseif p.k=="poke" then spr(36,p.x-8,p.y-4,2,1,p.dx<0) else circfill(p.x,p.y,2,p.k=="ember" and 9 or 7) end end camera() end
function bar(y,h,f,c) rectfill(2,y,50,y+h,1) rectfill(2,y,2+48*f,y+h,c) end
function drawhud() rectfill(0,0,127,15,0) bar(2,3,max(0,hp/maxhp),8) bar(7,2,min(1,xp/need),12) print("l"..lvl,53,2,7) spr(125,53,8) print(ess,62,9,7) print(tfmt(),76,2,7) print((karma>0 and "+" or "")..flr(karma),104,2,karma>0 and 11 or (karma<0 and 8 or 7)) if state=="play" then rectfill(0,16,127,17,1) rectfill(0,16,127*min(1,tsec/300),17,12) for q in all({28,55,106,112}) do pset(q,16,7) end local o=B or (E.shr and not E.shrdone and PL[1]) if o then local dx,dy=o.x-px,o.y-py if dx*dx+dy*dy>4900 then local a=atan2(dx,dy) circfill(64+cos(a)*50,68+sin(a)*44,3,B and 8 or 10) end end end if B then rectfill(14,120,114,124,1) rectfill(14,120,14+100*max(0,B.hp/B.mh),124,8) print(GN[B.god],54,113,7) end if bant>0 then local w=#bantxt*4+6 rectfill(64-w/2,20,64+w/2,29,0) print(bantxt,64-#bantxt*2,22,10) end end
function drawchoice() box(9,30,119,100) print(chsrc=="level" and "level up: choose" or "choose an upgrade",16,34,7) for i=1,#ch do local y=48+(i-1)*14 spr(UI[ch[i]],14,y-2) print((i==sel and "> " or "  ")..UN[ch[i]].." x"..U[ch[i]],26,y,7) end end
function drawmodal() box(9,36,119,96) print(modal.t,16,40,10) for i=1,#modal.l do print(modal.l[i],16,48+(i-1)*6,7) end for i=1,#modal.o do print((i==modal.sel and "> " or "  ")..modal.o[i],16,80+(i-1)*7,7) end end
function drawtally() box(9,14,119,116) print("time "..tfmt().."  level "..lvl,16,20,7) print("kills "..kills.."  karma "..flr(karma),16,27,7) if markearned>0 then spr(markearned,16,36) print(marktxt,26,38,7) elseif marktxt~="" then print(marktxt,16,36,7) end if crownnote~="" then print(crownnote,16,46,10) end print("next form: "..(bank==1 and "asura" or FN[ladder(flr(karma))]),16,55,7) if #carry>0 then local cs="carried over: " for i=1,#carry do cs=cs..UN[carry[i]].." " end print(cs,16,66,11) end print("z: be reborn",16,106,5) end
function formnext() if bank==1 then return 7 end if lives==0 then return 1 end return ladder(flr(lastk)) end
function drawrebirth() cls(0) local nf=formnext() drw(FH[nf],64,38,32,32,FDS[2*nf-1]) local nm=FN[nf] print(nm,64-#nm*2,58,7) for r=0,1 do local tb=r==0 and sun or blood local y=76+r*12 for i=1,6 do if tb[i]==1 then spr(174+r,22+i*9,y) end end end if crown(sun) then spr(188,8,76) end if crown(blood) then spr(189,104,88) end if #carry>0 then print("kept:",16,102,11) for i=1,#carry do spr(UI[carry[i]],40+(i-1)*12,101) end end print("god mode: "..(GOD and "on" or "off").." (down: toggle)",8,112,GOD and 10 or 5) print(crown(sun) and crown(blood) and "z: normal life   x: ascension" or "z: begin life",14,122,10) end
function drawending() cls(0) print("you step off the wheel",22,40,10) print("no more marks. no more hunger.",14,56,7) print("the gods keep their thrones.",20,66,7) print("you keep the silence after.",22,76,7) print("z: return",48,100,5) end
-- entry
function _init() loadsave() state="rebirth" music(0) end
SU={level=updchoice,modal=updmodal,tally=updtally}
function _update60() fr+=1 if state=="rebirth" then if btnp(3) then GOD=not GOD loadsave() elseif btnp(5) and crown(sun) and crown(blood) then startlife(true) elseif btnp(4) then startlife(false) end elseif state=="ending" then if btnp(4) then state="rebirth" end else local f=SU[state] if f then f() else updateplay(1/60) end end end
function _draw() if state=="rebirth" then drawrebirth() return end if state=="ending" then drawending() return end drawworld() drawhud() if state=="level" then drawchoice() end if state=="modal" then drawmodal() end if state=="tally" then drawtally() end end
