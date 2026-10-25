pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
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
__gfx__
00044000000000000000000000000000000000000a7000000000000060006000000000dd0000d0000000000000000000000000000000000000000cc00044a400
0440044400044444000000000040400000000044007a0000000000055555556500000dd8000d00000000700000070000000ee000066666660000cccc04000040
000004440440044400000000004999000000044400070000000006059955555600000ddd000d0000000070000007000000ee7e0005355555000cc7c040000004
0000044400000444000000000099999400000f0f0007a0000000006999955550000000dd00d0000000077708887770000e2ee2e00555535500cc000040000004
0200044400000444000000000999999900000fff0007a00000000000995556000000000d00d000000007778888877000e2eaa2ee005501110cc0000040000004
002204420000044290000000099990f9000000ff0077000000000004400600000000000d0e0000000000088a8a880000eeeeeeee00550111cc00000004000040
00002492000024920900099999999ff800000011077a00000000000440000000000000dd0000000000000888888800003bbbbbb30055011ac000000000444400
00004992002249920409999999999fff000000110a000000000000044000000000000dee000000000000008888800000bbb00bbb005501190000000000000000
000049920200499200999499999999f0000000110000011100000004400000000000ddee00000dde00000228882200000880880a005501910770077099000099
02222992022229920099999999999900000001110000011100000004400000000000deee00000dee000022222222200088888880005501110880088090000009
00004992020049920099994949999900000001110000011100000004400000000000deee00000dee000222292222220087888880005501110880088000000000
00004492002244920009999999999000000001110000011100000004400000000000deee00000dee000222229222220088888880005500000880088000000000
00002442000024420000499999940400000001110000111100000004400000000000deee00000dee002022292922202008828800055555550880088000000000
00220442000004420000404000040400000011110000111100000004400000000000ddee00000dde000002292222000000888000055555550088880090000009
020000020000000200004040000404000000111100000011000000044000000000000dee000000de000000222220000000080000555555550008800099000099
0000000000000000000040400004040000001111000000000000000440000000000000d0000000dd000000022200000000000000666666660000000000000000
000000000000000000000066008000000000000000000000000000080000000a0000000000000000000000000000100033333333444444443333333333333333
00000000000000770000066600880000000000000000aaaa0000555800000007000066660000000000000044000010003b3333b3442449443b333b333b333333
0000000c000007770000666600088888000000000000a0000000558800000077000666660aa00aa0000004440001100033333333444444443333333333333444
00000000000077770000660600088888aaaaaaaaaaaaa0000000555500a0007c0006666600000000000004440001000033b33b33494444243434434333334444
00000bbb000070770000666000088888999999999999aaaa000055ff000007cc006666660000000000000f0f0000100033333b33444444444444444433344444
0c00bbbb000077770000660020088a88000000000000a00000000fff000077cc005555550000000000000fff000100003b333333444944444494444433444444
000bbbbb000007670000666022088888000000000000aaaa005558ff00007ccc0056116600000000000000ff000101003333b3b3424444494444442434444444
00bbbbbb0000076700006666022887870000000000000000055555ff0007711c00566666000000000000cccc0010000033333333444444444444444444444444
00bbbbbb0000076700606666022088887700007700000000055555ff00077ccc00566566000000880000cccc000000000000000000999499999999f00000d000
00bbb0bb0000000600066666002088887770077700000000055522250a007cc10056656666666688000ccccc00e0a000001110000099999999999900000d0000
00bbbbbb00006666000655550020888807777770000000000055222500007ccc0056661655555558000c44440b0b0b00010010100099994949999900000d0000
00bbb0bb00000006000666660000088800077000000000000000222a0000077c0056666605500000000c055000b7b00001100110000999999999900000d00000
00bbb0bb000066660006655500008888000660000000000000002225000007770055611105500000000f05500b0b0b00001111000004099999900040edd00000
00000b00000000060006666600008888077777700000000000002225000000cc0006666605500100000005500000000000011000000400040040004000000000
000000000000666600066066000008007770077700000000000025550000000c0006666605500000000005500000000000000000000400040040004000000000
000000000000000000660006000008007700007700000000000005500000000c0005555555550000000000000000000000000000000400040040004000000000
0000000000000000000000000000000000000000ffff000000000009000000008888888888888888444444444444444444444444444444444444444466566656
000000000000000000000000000000000000000feefff00000000098008888009898989898989898ffffffffffffffffff4444ff44ffffff4494444466566656
000000000050000000000000000000000000000ffffff00000000988088888808888888822222222ffffffffff4444ffff4224ff44ffffff4444449456665666
000000000550000000000000000e000000000000ffffff0000009898089898908989898982828282f7ffffffff4aa4ffff4224ff44ff7fff4442444456665666
00000000555511000000000000eee000000000000ffffff000098888888888888888888888888888ffffffffff4444ffff4444ff44ffffff4944444466566656
00000005555111100000000000eee00000000000ffff07ff00988888989898989898989828282828ffffff7fff4aa4ffff444aff44ffffff4444494466566656
50000055551118410000000000dedd0000000000ffff00ff09898898888888888888888888888888ffffffffff4444ffff4444ff44ffffff4444444456665666
5500155555111144e000ddddddddd8d000700000ffeefff298888888222222222222222222222222ffffffffffffffffff4444ff44ffffff4494444956665666
5551555555511140e0ddddddddddddd200f000004ffffff000000000440000006665666666656666000000000000000006566560666666660000000066666666
55111155551111000ddddddddddddd70000fff7ff4ffff0000000000444444446665666666656666000006660000000006566560555555550000000066566656
55511115111100000dddddddddddd070000f7fff7400000000b00b00440000005555555555555555000066660000000006566560066666600000000066666666
500011111110000000ddddddddd0000000fff7fffff0000000b03b00440000006656666566500665000666660666666006566560006556000006600066665666
0000000000000000000ddddddd000000000fffffff0000000b3b03b0444444446656666566500665006665660655556006566560006666000066650065666666
0000000000000000000d00d00d0000000004ffff400000000b3b03b0440000005555555566500665066666660666666006566560006666000665666066666566
0000000000000000000d00d00d00000000040000400000000000000044000000666566665555555556666666666666660656656000000000666566d566666666
00000000000000000000000000000000000400004000000000000000440000006665666666566665555555555555555506566560000000005555555566666666
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
11131111333b333333333333111b111133333333333b333311131111333b333333333333111b111133333333333b333311131111333b333333333333111b1111
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
11111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111333333333333333311111111
0007000007777770000000000000060000000000000000000008000000080000000aaa00088088007777777700000000aa000aa0000cc0000000900044444440
00070000700000070000000000040600000000b000000000000880000800008000a770008888888055555555000ee0000aa0aa0000cccc000000099004444400
000760000077770066000000004006000000b00b06666660008880000099090000aaaaaa8e88888056555565000ee00000aaa0000c7cccc069999999004a4000
00076000070000700088800004400600700b00b06007600600898800000aa0000aaaaaa088888880555555550eeeeee0000a0000ccccccc066999999000a0000
00aaa00000077000668788000440060070b070006006700608898880809aa0900aaaaa0008888800055555500eeeeee000aaa0000ccccc0069999999004a4000
00040000007007000088888800400600700b00b0066666600899988000900900aaaa00000088800005555550000ee0000aa0aa0000ccc0000000099004a4a400
000400000007700007777777000406000000b00b00000000089a98800800908000a000000008000000555500000ee000aa000aa0000c00000000900044444440
00090000000770000000000000000600000000b00000000000899800000000000a00000000000000000550000000000000000000000000000000000000000000
00007000700070000000000000000000000000000000000000000000000000000000000000000000000000000aaa00000000000000000000000000fffff00000
0000700777007000009000000000000000000000000000000000000000000000000000000000000a00000000aaaaa000000000000000000000000fffffff0000
000777777777770000990a0000b0b0b0000000000000000000000777077722770000000000a0000a0000000aaaaaaa0000000000000000900000fffffffff000
00077777777777000089000900b0b0b0000000000000000000000777077722770000000000aa00aa0000000aaa8aaa000000000000000999000f444fff444f00
0000770777077000099990090bbbbbbb000000000000000000000072227222270000000000aa00aa0000000aaaaaaa000000000000999999000fffffffffff00
00007080708070009900000000a0a0a0000000000000000000000072227222270000000000aaaaaa00000000aaaaa000000000000999944400fff0fffff0fff0
00007707770770000000000000b0b0b000000000003300000000022222222222000000000aaaaaaa000000000aaa0000000000009994499900fffffffffffff0
0000777707777000000000000000000000000000033330000000222222222222000000000aaaaaaa0000000000400000000000099999999900fffffffffffff0
00000777777700000a000000000000000000000033333300000222222222222200000000099999990000000010f00000000000994999999900fffff222fffff0
000000777770000000000000090000900000000033333300000222222222222200000000099999990000000111410000000009994999999900ffffff2ffffff0
00000222222200000000000099900999000000003333330000022222222222220000000000000fff0000000111410000000099949999999900ffffff4ffffff0
0002222222222200000000000909909000000000033333330002222222222222000000000000ffff00000011114100000000994999999999000f4fff4fff4f00
002222222222222000900000009999000000000033333333000222222222888800000000000fffff00000011114100000000994999999999000f4fff4fff4f00
00722222222227200990000000099000000000333333333300002222228888820000000000ffffff000000111141000000099499999999990000f444f444f000
00722222222227200990000004040040000033333333333300000222888888820000000000fff1ff0000011111410000009994999999999900000fffffff0000
00722222722227209999000000000000000333333333333300000022888888820000000000ffffff000001a1114100000009949999999999000000fffff00000
02722222722227220009900000000000003333333333333300000eeeeeee00000000000000ffffff000000000000000000000000000000000009900000080000
027227777777272200000000000000000033333333333333000ee0fffff0ee0000000000000fffff000000000000000000000000000000000900009000080000
07222222722222720080000000000000033333333333ffff00e0fffffffff0e0000000000000ffff00000000000000000000000000000000000aa00000888000
07222222a222227208800000003b30b0033333333fffffff00fffffffffffff00000000000000fff0000000000000000000000000000000090a7aa0908888800
0722277888772270088000000bbbbb0b03333333ffffffff0fffffffffffffff00000000000111110000000000000000000007070707000090aaaa0908888800
072222228222227088880000033b33b00333333fffffffff0ffffffeeeffffff000000000071111a00000000000000000000077777770000000aa00008788800
072222227222227000088000003b3000033333ffffffffffffffffe7ffefffff000000000011111a000000000000000000000777777700000900009000888000
707227777777272700a0000000303000003333fffffffffffffffefffffeffff000000000011111a000000100010000000000777677700000009900000000000
00222222722222200009000007777770003333fffffffffffffffefffffeffff000000000011111a0000000000000000a00aa00a800880080000766666660000
00222222722222200099000007000070000333fffffffffffffffefffffeffff000000000111111a0000000000000000aaaaaaaa228228220006666666615000
002222227222222000990000070660700033333fffffffffffffffefffefffff000000000111111a0000000000000000aaaaaaaa222222220006665555165000
0002222222222200099990000700007003333333ffffffff0ffffffeeeffffff000000001111111a0000001111100000aaaccaaa222882220006666556165000
00022202220222000000990807060070333333333fffffff0fffffffffffffff000000001111111a0000000000000000aaaaaaaa222222220006665555665000
00022002220022000000000807000070333333330003ffff00fffffffffffff0000000001111111a000000000000000000000000000000000006666666635000
00020000200002000000008807777770033333300000000000e0fffffffff0e0000000011111111a000000000000000000000000000000000053555555555500
000000002000000000000888000000000033330000000000000ee0fffff0ee0000000001111111110000000000000000000000000000000003b0555555550b30
00000aaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000eeee0000000000a0600000a0000000a000000aa7
00000aaa8aaa000000000000c000000000000000000000000000000000000000000000aa000000aa00e00000eeeee000000000af060000af000000af00000aa7
00000aaaaaaa00000000000cac00000000000000000000000000000000000aaa00000aaa00000aaa0e7ee000ee77ee0000000aaa00400aaa00000aaa00000aa7
00000004440000000000000cac00000000077777777777000000000000aaaaaa00000a0f00000a0feee7eeee0ee77ee000000f8f60040f8f00000f8f00000777
0000000777000000000000ccacc000000077777777777770000000000aaaaaaa00000aaf00000aafeee77eee0ee777ee06000fff60004fff00000fff00000777
000000777770000000000cc7a7cc000000777778887777700000070aaaaaa00000000aaf00000aafeee7777e0ee7777e060000ff060004ff000000ff00000777
000007778777000000000cc7a7cc00000777778888877777000000aaaaa0044400000aa700000aa70ee7777000e777ee00644011004000410000000100000777
00000778087700000000cc77a77cc000077778888888777700000aa88004400000000aa700000aa70ee777e0000ee7ee00000444000449940000444400000777
00aaa7788877aaa00000cc7cac7cc0007a7778888888777a00000aaa0040000000000aa700000aa70ee777e00000e00000000999000004996444009900000aa7
00aaa7778777aaa00000ccc7a7ccc00007777888888877770000aaa00400000000000aa700000aa700eeeee00000000006000999000009490000009900000aa7
00aaaa77777aaaa00000cc77a77cc0000777778888877777000aaaa04000000000000aa700000aa700eee0000000000006000444000009940000004400000aa7
00000077776000000000cc77a77cc0000077777888777770000aaa04000000000000007700000777000e00000000000000644111000001110044441100000077
0000007676600000000cc77cac77cc000077777777777770000aaa04000000000000007700000777000000000000000000000111000001116400001100000077
0000007676600000000cccc7a7cccc00000777777777770000aaa04000000000000000770000077a000000000000000000001111000011110000011100000007
0000007676600000000cc777a777cc00000000000000000000aaa0400000000000000077000007a7000000000000000000001111000011110000011100000007
00000076a6600000000cc777a777cc00000000000000000000aaa040000000000000007700000000000000000000000000001111000011110000011100000007
0000007676600000000cc77cac77cc0000000000000000000000000000000000000000000000a00000aaaa0077000077000cc000a000000a0000000000000060
00000076766000000000ccc7a7ccc0000000000000000000000000000000000000000000004444440a0000a078800887000cc000000ee0000000006666667660
00000076766000000000cc77a77cc000000000000000000000000000000000000000000000444444a000000a0888888000c77c0000ee7e000000066777776666
00000076766000000000cc77a77cc0000000000000aa000000088800800888000000000000aaaaaaa000000a08e8888000cccc000e2ee2e00000667777666600
00000076a66000000000cc7cac7cc000000000000aa0aaaa008777788877778000fffffa000000000a0000a0008888000cccccc0e2eaa2ee0006777776600000
000000767660000000000cc7a7cc00000000000aaa0aa0000087788888887780004444aa0000000000aaaa00000880000cc7ccc0eeeeeeee0067666660000000
00000076766000000000ccc7a7ccc000000000aaaaa004440877788888887778004444a0000aaaaa000000000000000000cccc003bbbbbb30466660000000000
000000767660000000000cc7a7cc000000000aa8a00040000877888888888778004444a0000aaaaa000000000000000000000000bbb00bbb4006000000000000
0000006676600000000000ccacc0000000000aaa0000000087778888888887770044444aa00aa00a770000770008800000006000070000000022220000ffff00
000000667660000000000cccaccc00000000aa000400000008778888888887780044444a0a0000a077700777008888000000666677000000022220000ffffff0
00000006660000000000c00cac00c000000aaaa04000000008777888888877780044404a000aa0000777777000888800000066760555555022200000ff4ff4ff
000000066600000000000000a0000000000aaa040000000000877888888877800044444a00aaaa000088880008888880000046660555555022000080ff4ff4ff
000000006000000000000000a0000000000aaa040000000000877778887777800044444a0099990000800800088288800000400605595550222000000ffffff0
000000006000000000000000a000000000aaa0400000000000088888888888000044404a00999900000000000088880000040000055595500222200000ffff00
000000000000000000000000a000000000aaa0400000000000000000000000000044444a44444444000000000008800000040000005555000022220000044000
0000000000000000000000000000000000aaa0400000000000000000000000000000000033333333000000000000000000400000005555000000000000000000
__sfx__
001800001a040000000000000000000000000000000000001d030000000000000000000000000000000000001a040000000000000000000000000000000000002403000000000000000000000000000000000000
001800003904000000000000000035040000000000000000320400000000000000003003000000000000000032040000000000000000000000000000000000002d03000000000000000032040000000000000000
0018000000000000003252000000000000000035520000000000000000395200000000000000003552000000000000000032520000000000000000305200000000000000002d5200000000000000002952000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00001a140000001a140000001a140000001a140000001d140000001d140000001a140000001a140000001a140000001a140000001a140000001a14000000211400000021140000001f140000001f14000000
000f00003244000000000000000035440000000000000000394400000000000000003744000000000000000035440000000000000000344400000000000000003244000000000000000030430000003243000000
000f00000000000000325200000000000000003552000000000000000039520000000000000000355200000000000000003252000000000000000035520000000000000000395200000000000000003552000000
000f00000a630000003262000000000000000032620000000a630000003262000000000000000032620000000a630000003262000000000000000032620000000a63000000326200000000000000003262000000
000f00001a140000001a140000001a140000001a140000001d140000001d140000001f140000001f140000001a140000001a140000001a140000001a140000002414000000241400000021140000002114000000
000f0000394400000000000000003c440000000000000000394400000000000000003744000000000000000035440000000000000000394400000000000000003744000000000000000035430000003443000000
000f0000000000000035520000000000000000395200000000000000003c520000000000000000395200000000000000003552000000000000000039520000000000000000375200000000000000003552000000
000f00000a630000003262000000000000000032620000000a630000003262000000000000000032620000000a630000003262000000000000000032620000000a63000000326200000022630000001a63000000
000b00001a150000001a150000001b150000001a150000001a150000001a1500000019150000001a150000001a150000001a150000001b150000001a150000001d150000001c150000001b150000001a15000000
000b0000322400000032240000003524000000332400000032240000003124000000322400000000000000002d2400000000000000002e2400000000000000002d24000000000000000035240000003324000000
000b000000000000003252000000000000000035520000000000000000395200000000000000003a5200000000000000003952000000000000000035520000000000000000325200000000000000002e52000000
000b00000a6300000032620000000a63000000326202c6200a6300000032620000000a63000000326202c6200a6300000032620000000a63000000326202c6200a6300000032620000000a63000000326202c620
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000026450294502d4503245035450394500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000039450000003e4500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000126600e6600a6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003e2503c2503925037250352503425032250302502d2502b25029250282502625024250212501a25000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800003503000000000000000000000000003903000000000000000000000000003e03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00010220
01 04050607
02 08090a0b
03 0c0d0e0f
