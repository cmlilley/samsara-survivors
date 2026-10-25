pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
GOD=false
-- samsara survivors: data-driven rewrite (entity modes, boss sequencer, event places)
fr=0
GN={"narak","vora","ferrox","aurel","kharun","lumara","the judge"}
FN={"soul mote","deva","virtuous human","animal","hungry ghost","hellborn","asura"}
FHP=split("60,140,120,105,90,75,150")
FSPD=split(".95,1.2,1.15,1.1,1.05,1,1.25")
FDMG=split(".9,1.25,1.15,1.1,1.05,1,1.35")
FH=split("64,47,97,66,98,68,77") FCAP={3,8,6,5,4,4,8}
EN={"slime","rat","skeleton","soldier","guardian","wisp","ghost","imp","big slime","brute","turret"}
-- foe rows: hp,spd,dmg,ess, mode, a,b,c,d,e,pspd
-- modes: 1 pulse, 2 weave, 4 shooter, 5 melee, 6 phase
-- shooter a=proj b=cd c=pdmg d=band-in e=band-out; melee a=jab-dmg b=jab-cd
ETS={"6,.35,4,1,1,0,0,0,0,0,0,.8,.4375,0,0,0,8","4,.8,3,1,2,0,0,0,0,0,0,0,0,0,0,0,8","8,.4,4,3,4,bone,2.2,5,62,48,1.7,0,0,0,0,0,8","40,.3,12,12,5,18,1.6,0,0,0,0,0,0,0,0,0,8","26,0,6,6,4,bolt,2.6,6,0,0,1.1,0,0,0,0,0,8","5,.5,6,3,1,0,0,0,0,0,0,2.4,.5,.3,0,0,8","7,.55,0,2,1,0,0,0,0,0,0,.8,.4375,0,0,0,8","14,.45,4,8,4,poke,2.8,5,54,40,1.9,0,0,0,0,0,8","24,.3,6,9,1,0,0,0,0,0,0,.8,.4375,0,0,24,12","220,.28,18,45,5,24,1.2,0,0,0,0,0,0,0,0,0,16","20,0,0,6,4,bolt,2,5,0,0,1.8,0,0,0,0,0,8"}
ET={} for i=1,11 do ET[i]=split(ETS[i]) end
FSN=split("99,72,100,101,102,103,104,105,99,101,106")
FSF=split("0,1,0,0,0,0,0,0,0,0,0")
FDS=split("0,64,0,47,0,97,1,66,0,98,1,68,0,77")
PT=split("6,7,5,8,4")
PKS={ess=132,heart=127}
function ucap(i) return min(UM[i],asc and 8 or FCAP[form]) end function mkcarry() carry={} for i=1,11 do if saved[i]>0 then add(carry,i) end end end LAY=split("145,146,-145,147,148,150,148,149,147") ANC=split("96,544,552,424")
-- boss patterns per god, split rows: mv,mind,cd, akind, params...
-- akind: 1 pend(p1: 2 dash/3 swipe, p2 delay, p3 dash-spd)
-- 3 fan(n,step,sp,dm) 4 zones(p1: 1 patches/2 beams)
-- 5 set(p1: 1 vac/2 kwaves)
BPS={".6,36,2.6,4,1",".22,46,3.5,5,1",".5,0,2.6,1,2,.6,4",".15,70,1,3,3,.1,2,7","0,0,2.4,5,2",".3,42,3.2,4,2",".45,30,0,0"}
BP={} for i=1,7 do BP[i]={split(BPS[i])} end
BSP=split("0,0,6,2,8,3,10,2,2,0,4,0,12,3")
JACT={bolt={0,0,1.4,3,5,.06,2,7},melee={0,0,1.8,1,3,.5}}
UN={"melee","bolt","spread","damage","speed","max hp","armor","regen","crit","cooldown","magnet"}
UI=split("134,135,136,137,138,139,140,141,142,143,144")
UM=split("5,5,4,5,5,5,5,5,5,5,5")
PL={{x=128,y=600},{x=640,y=120},{x=620,y=660}}
-- utils
function cl(v,a,b) return mid(a,v,b) end
function dst(x1,y1,x2,y2) local dx,dy=x2-x1,y2-y1 return sqrt(dx*dx+dy*dy) end
function ang(x,y) return atan2(x,y) end
function adf(a,b) return abs(((a-b+.5)%1)-.5) end
function dp(t) return dst(px,py,t.x,t.y) end
function dd(a,b) return dst(a.x,a.y,b.x,b.y) end
function ap(t) return ang(px-t.x,py-t.y) end
function af(t) return ang(t.x-px,t.y-py) end

function ban(t) bantxt=t bant=3 end

function box(x0,y0,x1,y1) rectfill(x0,y0,x1,y1,0) rect(x0,y0,x1,y1,5) end
function nearfoe(x,y,r,e1,e2,e3) local bt,bd=nil,r for e in all(foes) do if e.hp>0 and e~=e1 and e~=e2 then local d=dst(x,y,e.x,e.y) if d<bd then bt,bd=e,d end end end return bt,bd end
-- save
function crown(a) for i=1,6 do if (a[i]==0) return false end return true end

function loadsave() cartdata(GOD and "samsara_god" or "samsara_v1") if dget(36)~=777 then for i=0,63 do dset(i,0) end dset(36,777) dset(32,100) end sun={} blood={} saved={} for i=1,6 do sun[i]=dget(i) blood[i]=dget(6+i) end for i=1,11 do saved[i]=dget(39+i) end mkcarry() bank=dget(31) lastk=dget(32)-100 lives=dget(35) end
-- stats



function recalc() local bh=asc and 150 or FHP[form] local bd=asc and 1.35 or FDMG[form] maxhp=bh+bmax+18*U[6] hp=min(hp,maxhp) dmgs=bd*(1+.12*U[4]) if form==6 then dmgs*=1.05 end spd=1.4*FSPD[form]*(1+.09*U[5])*(GOD and 1.5 or 1) pdmg=10*dmgs*(1+.22*U[1]) bdmg=7*dmgs*(1+.22*U[2]) rng=20+3*U[1] mag=(16+10*U[11])*(form==5 and 2 or 1)*(GOD and 3 or 1) essm=form==5 and 1.2 or 1 armor=U[7] regen=(form==2 and .5 or 0)+.6*U[8] critc=.11*U[9] end
function ladder(k) return k>=60 and 2 or k>=20 and 3 or k>=-19 and 4 or k>=-59 and 5 or 6 end
function kadd(v) karma=cl(karma+v,-100,100) end
function heal(v) hp=min(maxhp,hp+v) end
function gainxp(v) v*=essm ess+=flr(v) xp+=v while xp>=need do xp-=need lvl+=1 lvlq+=1 need=5+4*lvl+lvl*lvl end end
-- life setup
function startlife(a) asc=a foes,pp,ep,pk,zn,ac,B={},{},{},{},{},{},nil U={} for i=1,11 do U[i]=0 end lvl,xp,need,ess,kills,bmax=1,0,10,0,0,0,0 karma=lastk hp,px,py,face,pinv,pcd,bcd,avt,tsec,df,lvlq=1,384,384,.25,0,0,0,0,0,0,0 if asc then form=1 elseif bank==1 then form=7 bank=0 dset(31,0) elseif lives==0 then form=1 else form=ladder(flr(lastk)) end for i=1,11 do U[i]=min(saved[i],ucap(i)) end lives+=1 dset(35,lives) recalc() hp=maxhp spawnt,endt,markearned=1,0,0 marktxt,crownnote="","" nextinn,fedt,pacc,ascidx,ascnext=6,0,0,1,20 lastr=0 cht=25 for P in all(PL) do P.done=false P.ch=0 P.on=false end state="play" ban(asc and "ascension life" or FN[form]) music(asc and 3 or 1) end
-- drawing helpers
function shad(x,y,r) rectfill(x-r,y+6,x+r,y+8,1) end
function drw(n,x,y,w,h,m,f) local sx,sy=(n%16)*8,flr(n/16)*8 if m==0 then sspr(sx,sy,8,16,x-w/2,y-h/2,w/2,h) sspr(sx,sy,8,16,x,y-h/2,w/2,h,true) elseif m==1 then sspr(sx,sy,16,16,x-w/2,y-h/2,w,h,f) elseif m==2 then sspr(sx,sy,16,h,x-16,y-h/2,16,h) sspr(sx,sy,16,h,x,y-h/2,16,h,true) else sspr(sx,sy,16,16,x-16,y-16,16,16) sspr(sx,sy,16,16,x,y-16,16,16,true) sspr(sx,sy,16,16,x-16,y,16,16,false,true) sspr(sx,sy,16,16,x,y,16,16,true,true) end end
function drawform(f,x,y,fa,at,m,pv) local fx,fy=cos(fa),sin(fa) local ff=fx<0 local n=FDS[2*f] if m then y+=(f==2 and sin(fr*.07)*2.5 or sin(wph)*1.1) end if f==1 then n=fr%12<6 and 64 or 65 elseif f==2 then local wn=(at>0 or fr%24<12) and 76 or 75 local wy=y-6-(wn==76 and 2 or 0) spr(wn,x-12,wy,1,2) spr(wn,x+4,wy,1,2,true) if at>0 then n=74 end elseif f==7 then n=at>.1 and 79 or at>0 and 96 or 77 end drw(n,x,y,16,16,FDS[2*f-1],ff) if f==4 and m and sin(wph)<0 then local c1,c2=125,126 if ff then c1,c2=126,125 end spr(c1,x-8,y,1,1,ff) spr(c2,x,y,1,1,ff) end if f==3 then line(x+fx*3,y+fy*3,x+fx*10,y+fy*10,4) elseif f==6 then spr(70,at>0 and x+fx*10-8 or x+(ff and -16 or 4),at>0 and y+fy*10-8 or y-6,2,2,ff) end if f==2 then for i=0,2 do local a=fr*.04+i/3 pset(x+cos(a)*12,y+sin(a)*5,10) end end if pv and form==2 then circ(x,y-13,4,10) end end


function addpick(k,x,y,v) add(pk,{k=k,x=cl(x,10,758),y=cl(y,10,758),v=v or 1}) end
function spawnpos() local a=rnd() local r=95+rnd(55) return cl(px+cos(a)*r,10,758),cl(py+sin(a)*r,10,758) end
function spawnfoe(t,x,y) if not x then x,y=spawnpos() end local b=ET[t] local e={k=t,x=x,y=y,face=.25,kx=0,ky=0,burn=0,tm=rnd(),acd=.5+rnd(1.5),hp=b[1]*(1+.2*tmin),dmg=b[3],ess=flr(b[4]*(1+.25*tmin)),scale=b[16],r=b[17],w=b[16]>0 and b[16] or 16,h=16} add(foes,e) return e end
function rpick(t) return t[flr(rnd(#t))+1] end
function pickn(p,c) local o={} for i=1,c do local j=flr(rnd(#p))+1 add(o,p[j]) p[j]=p[#p] p[#p]=nil end return o end
function picktype() local m=tmin if m==0 then return rnd()<.12 and 3 or flr(rnd(2))+1 end local o={1,1,2,2,3} for i=1,5 do if m>=i then add(o,PT[i]) end end if m>=3 and rnd()<.1 then return 9 end return rpick(o) end
function addep(x,y,a,sp,d,k) add(ep,{x=x,y=y,dx=cos(a)*sp,dy=sin(a)*sp,d=d,k=k,t=0,life=2.5/sp}) end
function hurt(d,u) if GOD then return end if u then if hp>0 then hp-=d end return end if pinv>0 or hp<=0 then return end sfx(42) hp-=max(1,d-armor) pinv=.5 end
function dmgx(t,d,crit,kx,ky,src) if t.hp<=0 then return end if t.god==4 and t.shield then d*=.25 end if crit then d*=2 end if GOD then d*=15 end t.hp-=d if t.k then t.kx+=kx t.ky+=ky end if form==6 and (t.god or src==1) then t.burn=3 end if t.god and t.hp<=0 then killboss() end end
function killfoe(e) kills+=1 addpick("ess",e.x+rnd(9)-4,e.y+rnd(9)-4,e.ess) if e.k==9 then for i=1,2 do spawnfoe(2,e.x+rnd(13)-6,e.y+rnd(13)-6) end end if e.k==10 then pendingrival=true addpick("chest",e.x,e.y) end end
function sweepfoes() for e in all(foes) do if e.hp<=0 then killfoe(e) del(foes,e) end end end
function killboss() sfx(43) addpick(asc and "chest" or "heart",B.x,B.y) if B.judge then pendingfinal=true B=nil return end if asc then ascidx=B.god+1 B=nil return end markearned=0 if B.form=="feral" then marktxt="no mark: feral god" else local tr=B.form=="trial" local tb=tr and sun or blood local was=crown(tb) tb[B.god]=1 dset((tr and 0 or 6)+B.god,1) markearned=tr and 128 or 129 marktxt=(tr and "sun mark: " or "blood mark: ")..GN[B.god] if not tr then bank=1 dset(31,1) end if not was and crown(tb) then crownnote=tr and "crown of heaven earned" or "crown of hell earned" end end B=nil endt=1 end
-- combat
function nearT(x,y,r,ph) local bt,bd=nearfoe(x,y,r,nil,nil,ph) local bk=bt and "f" or nil if B then local d=dst(x,y,B.x,B.y) if d<bd then bk,bt,bd="b",B,d end end return bk,bt,bd end
function arhit(r,d,src) local kb=src==1 and 1.5 or 0 for e in all(foes) do if e.hp>0 and dp(e)-e.r<=r then local a=af(e) if adf(a,face)<=1/6 then dmgx(e,d,src==1 and rnd()<critc,cos(a)*kb,sin(a)*kb,src) end end end if B and dp(B)-16<=r and adf(af(B),face)<=1/6 then dmgx(B,d,src==1 and rnd()<critc,0,0,0) end end
function doswing(tg) face=af(tg) avt=.16 arhit(rng+3,pdmg,1) end
function firebolt(tg) local a=af(tg) local n=1+U[3] for i=1,n do local aa=a+(i-(n+1)/2)*.035 add(pp,{x=px,y=py,dx=cos(aa)*3.2,dy=sin(aa)*3.2,d=bdmg,life=.62}) end end
function attacks(dt) pcd-=dt bcd-=dt avt=max(0,avt-dt) local cdm=max(.4,.9^U[10]) if pcd<=0 then local bk,tg,d=nearT(px,py,9999,true) if tg then local ed=d-(bk=="b" and 16 or tg.r) if ed<=rng then doswing(tg) pcd=.55*cdm end end end if bcd<=0 then local tg,bd=nil,112 for e in all(foes) do if e.hp>0 then local d=dst(px,py,e.x,e.y) if d<bd and d-e.r>rng then tg,bd=e,d end end end if not tg then local _,t2=nearT(px,py,112,true) tg=t2 end if tg then firebolt(tg) bcd=.9*cdm end end end
function updpp(dt) for p in all(pp) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=false if B and dd(p,B)<18 then dmgx(B,p.d,rnd()<critc,0,0,0) dead=true else local hit=nil for e in all(foes) do if e.hp>0 and dd(p,e)<e.r+2 then hit=e break end end if hit then dmgx(hit,p.d,rnd()<critc,0,0,1) dead=true end end if dead or p.life<=0 or p.x<-8 or p.x>776 or p.y<-8 or p.y>776 then del(pp,p) end end end
function updep(dt) for p in all(ep) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=p.life<=0 or p.x<-8 or p.x>776 or p.y<-8 or p.y>776 if dp(p)<5 then hurt(p.d) dead=true end if dead then del(ep,p) end end end
-- enemies: one update, mode-dispatched from the ET row
function movefoe(e,tx,ty,sp) local d=dst(e.x,e.y,tx,ty) if d>1 then local a=ang(tx-e.x,ty-e.y) e.x+=cos(a)*sp*df e.y+=sin(a)*sp*df e.face=a end end
function updfoe(e,dt) e.tm+=dt if e.burn>0 then e.burn-=dt e.hp-=2*dt end e.x=cl(e.x+e.kx*df,8,760) e.y=cl(e.y+e.ky*df,8,760) e.kx*=.8 e.ky*=.8 local r=ET[e.k] local sp=r[2] local d=dp(e) e.acd-=dt local m=r[5] if m==1 then local pu=e.tm%r[12]<r[12]*r[13] and 1 or r[14] if pu>0 then movefoe(e,px,py,sp*pu) end elseif m==2 then local a=ap(e) movefoe(e,px+cos(a+.25)*14,py+sin(a+.25)*14,sp) elseif m==4 then if d>r[9] then movefoe(e,px,py,sp) elseif d<r[10] then movefoe(e,2*e.x-px,2*e.y-py,sp) end if e.acd<=0 and d<=88 then local a=ap(e)+rnd(.05)-.025 e.face=a addep(e.x,e.y,a,r[11],r[8],r[6]) e.acd=r[7] end elseif m==5 then if d>19 then movefoe(e,px,py,sp) end if d<=17 and e.acd<=0 then hurt(r[6]) e.acd=r[7] end end end
-- bosses: pattern data + shared act helpers + one sequencer
function spawnboss(g,fm) local x=cl(px+(rnd()<.5 and -80 or 80),30,738) local y=cl(py+(rnd()<.5 and -60 or 60),30,738) B={tm=0,pat=1,pt=4,acd=1,tele=0,ptm=0,tur=false,wcd=0,dash=0,vac=0,ring=3,burn=0,waves=0,god=g,form=fm,b1=BSP[2*g-1],bm=BSP[2*g],o1=g==3 and 38 or (g==7 and 44 or 0),oy=-8,x=x,y=y,hp=fm=="feral" and 1200 or 1600} B.mh=B.hp if g==7 then B.hp=2000 B.mh=2000 B.judge=true B.mode=max(U[2],U[3])>=U[1] and "bolt" or "melee" end ban(GN[g].." ("..fm..")") music(3) end
function bossfire(a,sp,d,k) addep(B.x,B.y,a,sp,d,k or "ember") end
function radial(n,sp,dm,off) local ra=off or rnd() for i=0,n-1 do bossfire(ra+i/n,sp,dm) end end
function fan(a,n,st,sp,dm) for i=-(n-1)/2,(n-1)/2 do bossfire(a+i*st,sp,dm) end end

function addzn1(x,y,r,w,b,d) add(zn,{k=1,x=x,y=y,r=r,wn=w,b=b,d=d}) end
function doact(A,a) local ak=A[4] local p1,p2,p3,p4=A[5],A[6],A[7],A[8] if ak==1 then B.tele=p2 B.pend=p1 B.ptm=p2 if p1==2 then B.dsp=p3 end elseif ak==3 then fan(a,p1,p2,p3,p4) elseif ak==4 then if p1==1 then for i=1,3 do addzn1(cl(px+(i-2)*22+rnd(13)-6,14,754),cl(py+rnd(25)-12,14,754),14,.7,4,6) end else for i=-1,1 do add(zn,{k=2,x=cl(px+i*24,8,760),w=8,wn=.8,b=1.5}) end end elseif ak==5 then if p1==1 then B.vac=2 else B.waves=3 B.wcd=0 end end end
function updboss(dt) if not B then return end B.tm+=dt if B.burn>0 then B.burn-=dt B.hp-=2*dt if B.hp<=0 then killboss() return end end B.pt-=dt if B.pt<=0 then B.pat=B.pat%#BP[B.god]+1 B.pt=4 end B.tele=max(0,B.tele-dt) local d=dp(B) local a=ap(B) local sm=B.p2 and 1.4 or 1 local g=B.god local busy=false if g==2 and B.vac>0 then B.vac-=dt local va=af(B) px+=cos(va)*1.1*df py+=sin(va)*1.1*df busy=true if B.vac<=0 then fan(a,3,.12,2,5) for i=1,2 do spawnfoe(1,B.x+rnd(21)-10,B.y+rnd(21)-10) end end end if g==4 then B.shield=B.tm%10<6 B.o1=B.shield and 40 or 42 B.oy=B.shield and -14 or -16 if B.shield and not B.tur then B.tur=true for i=-1,1,2 do local te=spawnfoe(11,B.x+i*26,B.y+10) te.acd=rnd() end end if not B.shield then B.tur=false end end if g==5 then if d>60 and B.dash<=0 then movefoe(B,px,py,.25*sm) end if B.pat==1 and B.waves>0 and B.dash<=0 then B.wcd-=dt if B.wcd<=0 then fan(a,5,.06,2,7) B.waves-=1 B.wcd=.25 end end for i=0,2 do local sa=B.tm*.4+i/3 if dst(px,py,B.x+cos(sa)*20,B.y+sin(sa)*20)<7 then hurt(6) end end end if g==7 then if not B.p2 and B.hp<B.mh/2 then B.p2=true B.b1=228 B.o1=230 ban("the wheel breaks") end if B.p2 then B.ring-=dt if B.ring<=0 then radial(12,1.5,7,0) B.ring=3 end end end local P=BP[g][B.pat] if B.dash>0 then B.x+=B.dvx*df B.y+=B.dvy*df B.dash-=dt elseif not busy then local mv=P[1] if g==4 and not B.shield then mv=0 end if mv>0 and d>P[2] then movefoe(B,px,py,mv*sm) end end B.acd-=dt if B.acd<=0 and not busy then local A=P if g==7 then A=JACT[B.mode] end if g==4 and B.shield then A=nil end if g==5 and (B.dash>0 or (B.pat==1 and B.waves>0)) then A=nil end if A and A[4]>0 then doact(A,a) B.acd=A[3] end end if B.pend then B.ptm-=dt if B.ptm<=0 then local p=B.pend B.pend=nil if p==2 then local da=ap(B) B.dvx,B.dvy=cos(da)*B.dsp,sin(da)*B.dsp B.dash=.35 elseif p==3 then if d<48 then hurt(12) end end end end B.x=cl(B.x,16,496) B.y=cl(B.y,16,496) end


function spawnactor(x,y) local a={x=x,y=y,hp=3,inv=0,a=rnd(),dead=false} add(ac,a) return a end
function killactor(a,m) if a.dead then return end a.dead=true if m then kadd(-9) ban(m) else kadd(-3) ban("an innocent has fallen -3") end end
function updactors(dt) for a in all(ac) do a.inv=max(0,a.inv-dt) local fe=nearfoe(a.x,a.y,26) if fe then local fa=ang(a.x-fe.x,a.y-fe.y) a.x+=cos(fa)*.9*df a.y+=sin(fa)*.9*df else a.x+=cos(a.a)*.45*df a.y+=sin(a.a)*.45*df end if a.x<6 or a.x>762 or a.y<6 or a.y>762 then a.dead=true kadd(2,false) ban("an innocent passed safely +2") end if not a.dead and a.inv<=0 then for e in all(foes) do if e.hp>0 and dd(a,e)<10 then a.hp-=1 a.inv=.8 if a.hp<=0 then killactor(a) end break end end end if not a.dead and dp(a)<14 and btnp(5) then killactor(a,"you slew an innocent -9") end if a.dead then del(ac,a) end end end

function addupgrade(i) U[i]+=1 recalc() if i==6 then heal(12) end end

function placefx(chan) if chan then kadd(8,false) ban("prayer heard +8") else kadd(-8,true) local ow={} for i=1,11 do if U[i]>0 and U[i]<ucap(i) then add(ow,i) end end if #ow==0 then bmax+=12 recalc() heal(12) ban("+12 max hp") else addupgrade(rpick(ow)) ban("free upgrade") end ban("shrine smashed -8") end end
function places(dt) for P in all(PL) do if not P.done then if dp(P)>=26 then P.arm=true P.ch=0 P.on=false elseif P.arm then if btnp(5) then P.done=true sfx(44) placefx(false) else if btnp(4) then P.on=true end if P.on then P.ch+=dt heal(maxhp*.1*dt) if P.ch>=2 then P.done=true sfx(44) placefx(true) end end end else P.ch=0 end elseif dp(P)<26 then heal(maxhp*.04*dt) end end end
function dolock() lockform=karma>=30 and "trial" or (karma<=-30 and "war" or "feral") lockgod=1 for i=1,6 do local need=sun[i]==0 if lockform=="war" then need=blood[i]==0 elseif lockform=="feral" then need=need or blood[i]==0 end if need then lockgod=i break end end ban(lockform.." form: "..GN[lockgod]) for i=1,6 do spawnfoe(picktype()) end end
function events(dt) if tmin>lastr then lastr=tmin for P in all(PL) do P.done=false P.ch=0 P.arm=dp(P)>=26 P.on=false end if not asc then if tmin==1 then spawnfoe(7,104,576) spawnfoe(7,152,624) ban("the roadside shrine wakes") elseif tmin==2 then for i=1,6 do spawnfoe(picktype()) end elseif tmin==3 then spawnfoe(10) ban("mini-boss: the brute") elseif tmin==4 then dolock() elseif tmin==5 then spawnboss(lockgod,lockform) end end end if asc then if not B and ascidx<=6 and tsec>=ascnext then spawnboss(ascidx,"trial") ascnext+=35 elseif not B and ascidx>6 and not judgespawned and tsec>=215 then judgespawned=true spawnboss(7,"asc") end return end nextinn-=dt if nextinn<=0 then nextinn=8 if #ac<5 then local sa=rnd() local na=spawnactor(mid(16,px+cos(sa)*105,752),mid(16,py+sin(sa)*105,752)) na.a=ang(px-na.x,py-na.y)+rnd(.08)-.04 end end cht-=dt if cht<=0 then cht=45 addpick("chest",40+rnd(688),40+rnd(688)) ban("a chest has appeared somewhere") end end
function updpick(dt) for p in all(pk) do local d=dp(p) if p.k=="ess" then if d<mag then local a=ap(p) p.x+=cos(a)*3.5*df p.y+=sin(a)*3.5*df end if d<7 then sfx(41) gainxp(p.v) fedt=0 del(pk,p) end elseif p.k=="heart" then if d<9 then sfx(41) heal(25) del(pk,p) end elseif p.k=="chest" then if d<10 then del(pk,p) openchoices(3,"chest") return end end end end

function openchoices(n,src) sfx(40) local pool={} for i=1,11 do if U[i]<ucap(i) then add(pool,i) end end if #pool==0 then heal(25) ban("nothing left to learn: healed 25") state="play" return end ch=pickn(pool,min(n,#pool)) chsrc=src sel=1 state="level" end
function navc(c,n) if btnp(0) or btnp(2) then c-=1 end if btnp(1) or btnp(3) then c+=1 end return c<1 and n or c>n and 1 or c end
function updchoice() sel=navc(sel,#ch) if btnp(4) or btnp(5) then local src=chsrc addupgrade(ch[sel]) if src=="level" and lvlq>0 then lvlq-=1 openchoices(form==3 and 4 or 3,"level") else state="play" end end end
function setmodal(t,l,o,cb) modal={t=t,l=l,o=o,cb=cb,sel=1} state="modal" end
function docb(cb,s) if cb=="rival" then if s==1 then kadd(12) state="play" else kadd(-12) openchoices(3,"free") end elseif cb=="final" then if s==1 then state="rebirth" else state="ending" end end end
function updmodal() modal.sel=navc(modal.sel,#modal.o) if btnp(4) or btnp(5) then docb(modal.cb,modal.sel) end end
function entertally(r) if state=="tally" then return end diss=0 saved={} for i=1,11 do saved[i]=(U[i]+1)\2 dset(39+i,saved[i]) end mkcarry() lastk=flr(karma) dset(32,lastk+100) state="tally" end
function updtally() diss+=.015 if diss>=1 and btnp(4) then state="rebirth" music(0) end end
-- main update
function updateplay(dt) tsec+=dt tmin=flr(tsec/20) df=dt*60 bant=max(0,bant-dt) pinv-=dt fedt+=dt local mx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0) local my=(btn(3) and 1 or 0)-(btn(2) and 1 or 0) mvflag=false if mx~=0 or my~=0 then local l=sqrt(mx*mx+my*my) face=ang(mx,my) local sp=spd px=cl(px+mx/l*sp*df,10,758) py=cl(py+my/l*sp*df,10,758) mvflag=true wph+=.14 end events(dt) if state~="play" then return end places(dt) local cap=min(30,8+5*tmin) if not B and not asc then spawnt-=dt if spawnt<=0 and #foes<cap then spawnfoe(picktype()) spawnt=max(.22,1.05-.16*tmin) end end for e in all(foes) do if e.hp>0 then updfoe(e,dt) end end sweepfoes() updboss(dt) updactors(dt) attacks(dt) sweepfoes() updpp(dt) updep(dt) local inz=false for z in all(zn) do if z.wn>0 then z.wn-=dt else z.b-=dt if z.k==1 then if dp(z)<z.r then inz=true pacc+=dt if pacc>=.5 then pacc=0 hurt(z.d*.35,true) end end elseif abs(px-z.x)<z.w then hurt(10*dt,true) end end if z.b<=0 then del(zn,z) end end if not inz then pacc=0 end updpick(dt) if state~="play" then return end for e in all(foes) do if e.hp>0 and dp(e)<min(e.r,10)+6 then hurt(e.dmg) end end if B and dp(B)<22 then hurt(10) end if form==5 and fedt>5 and hp>maxhp*.3 then hp=max(maxhp*.3,hp-.5*dt) end if regen>0 then heal(regen*dt) end if hp<=0 then entertally("death") return end if endt>0 then endt-=dt if endt<=0 then entertally("boss") return end end if pendingrival then pendingrival=false setmodal("the rival soul",{"the brute falls.","his soul hovers, waiting.","mercy: +12 karma.","execute: -12 karma,","and steal an upgrade."},{"mercy","execute"},"rival",1) return end if pendingfinal then pendingfinal=false setmodal("the empty throne",{"the judge is defeated.","the throne sits empty,","the wheel is still.","sit: free play with gods.","step off: the true ending."},{"sit on the throne","step off the wheel"},"final",1) return end if not asc and tsec>=120 then entertally("time") return end if lvlq>0 then lvlq-=1 openchoices(form==3 and 4 or 3,"level") end end
-- drawing
function drawstr() for i=1,#ANC,2 do local x,y=ANC[i],ANC[i+1] for j=1,#LAY do local n=LAY[j] spr(abs(n),x+(j-1)%3*8,y+flr((j-1)/3)*8,1,1,n<0) end end end
function drawworld() camx=cl(px-64,0,640) camy=cl(py-64,0,640) camera(camx,camy) cls(3) for gy=flr(camy/8),flr((camy+120)/8)+1 do for gx=flr(camx/8),flr((camx+120)/8)+1 do local n=gy*96+gx local v=band(shr(peek(8192+n\4),(n%4)*2),3) if v==1 then pset(gx*8+3,gy*8+4,(gx+gy)%3==0 and 4 or 11) elseif v>1 then spr(149+v,gx*8,gy*8) end end end drawstr() rectfill(0,600,767,607,4) rect(1,1,766,766,5) for P in all(PL) do drw(106,P.x,P.y,16,16,0) if P.done then circ(P.x,P.y,26,1) else circ(P.x,P.y,26-P.ch*13,11) if dp(P)<44 then print("z: pray  x: smash",P.x-34,P.y-18,7) end end end for z in all(zn) do if z.wn>0 then if z.k==1 then circ(z.x,z.y,z.r,8) else line(z.x,0,z.x,767,10) end elseif z.k==1 then pal(12,8) drw(103,z.x,z.y,16,16,0) pal() else rectfill(z.x-z.w,0,z.x+z.w,767,10) end end for p in all(pk) do if p.k=="chest" then drw(108,p.x,p.y,16,16,0) else spr(PKS[p.k],p.x-4,p.y-4) end end for a in all(ac) do shad(a.x,a.y,5) drw(107,a.x,a.y,16,16,0,cos(a.a)<0) circfill(a.x,a.y-11,2,10) if dp(a)<16 then print("x: slay",a.x-10,a.y-19,8) end end for e in all(foes) do local k=e.k if k==11 then pal(5,9) pal(6,10) end drw(FSN[k],e.x,e.y,e.w,e.h,FSF[k],cos(e.face)<0) pal() if k==8 then spr(109,e.x-8,e.y-3,2,1) end end if B then local x,y=B.x,B.y shad(x,y,12) local g=B.god if B.bm==0 then spr(B.b1,x-8,y-16,2,4,g==5 and cos(B.tm*.3)<0,g==5 and sin(B.tm*.3)<0) else drw(B.b1,x,y,32,32,B.bm) end if g==1 and B.tele>0 then spr(46,x-16,y-16,1,4) spr(46,x+8,y-16,1,4,true) end if g==2 and B.vac>0 then drw(14,x,y+2,32,16,2) end if B.o1>0 then spr(B.o1,x-8,y+B.oy,2,2) end if g==5 then for i=0,2 do local sa=B.tm*.4+i/3 circfill(x+cos(sa)*20,y+sin(sa)*20,1,7) end end end shad(px,py,6) if not (pinv>0 and fr%4<2) then drawform(form,px,py,face,avt,mvflag,true) end if avt>0 then local fx,fy=cos(face),sin(face) spr(111,px+fx*16-4,py+fy*16-4,1,1,fx<0,fy<0) end for p in all(pp) do line(p.x-p.dx*2,p.y-p.dy*2,p.x,p.y,10) pset(p.x,p.y,7) end for p in all(ep) do if p.k=="bone" then spr(133,p.x-4,p.y-4) elseif p.k=="poke" then spr(109,p.x-8,p.y-4,2,1,p.dx<0) else circfill(p.x,p.y,2,p.k=="ember" and 9 or 7) end end camera() end
function bar(y,h,f,c) rectfill(2,y,50,y+h,1) rectfill(2,y,2+48*f,y+h,c) end
function drawhud() rectfill(0,0,127,15,0) bar(2,3,max(0,hp/maxhp),8) bar(7,2,min(1,xp/need),12) print("l"..lvl,53,2,7) print((karma>0 and "+" or "")..flr(karma),104,2,karma>0 and 11 or (karma<0 and 8 or 7)) for q=34,94,20 do pset(q,13,q<64 and 8 or 7) end line(64+karma\2,12,64+karma\2,14,10) if state=="play" then rectfill(0,16,127,17,1) rectfill(0,16,127*min(1,tsec/120),17,12) for q=0,4 do pset(21+q*21.17,16,7) end if B then local dx,dy=B.x-px,B.y-py if dx*dx+dy*dy>4900 then local a=atan2(dx,dy) circfill(64+cos(a)*50,68+sin(a)*44,3,8) end end end if B then rectfill(14,120,114,124,1) rectfill(14,120,14+100*max(0,B.hp/B.mh),124,8) end if bant>0 then local w=#bantxt*4+6 rectfill(64-w/2,20,64+w/2,29,0) print(bantxt,64-#bantxt*2,22,10) end end
function drawchoice() box(9,30,119,100) print(chsrc=="level" and "level up: choose" or "choose an upgrade",16,34,7) for i=1,#ch do local y=48+(i-1)*14 spr(UI[ch[i]],14,y-2) print((i==sel and "> " or "  ")..UN[ch[i]].." x"..U[ch[i]],26,y,7) end end
function drawmodal() box(9,36,119,96) print(modal.t,16,40,10) for i=1,#modal.l do print(modal.l[i],16,48+(i-1)*6,7) end for i=1,#modal.o do print((i==modal.sel and "> " or "  ")..modal.o[i],16,80+(i-1)*7,7) end end
function drawtally() box(9,14,119,116) print("time "..flr(flr(tsec)/60)..":"..(flr(tsec)%60<10 and "0" or "")..flr(tsec)%60 .."  level "..lvl,16,20,7) print("kills "..kills.."  karma "..flr(karma),16,27,7) if markearned>0 then if markearned==129 then pal(10,8) end spr(128,16,36) print(marktxt,26,38,7) elseif marktxt~="" then print(marktxt,16,36,7) end if crownnote~="" then print(crownnote,16,46,10) end print("next: "..(bank==1 and "asura" or FN[ladder(flr(karma))]),16,55,7) if #carry>0 then print("kept: "..#carry.." upgrades",16,66,11) end print("z: be reborn",16,106,5) end

function drawrebirth() cls(0) local nf=bank==1 and 7 or lives==0 and 1 or ladder(flr(lastk)) drw(FH[nf],64,38,32,32,FDS[2*nf-1]) local nm=FN[nf] print(nm,64-#nm*2,58,7) print("bosses defeated",34,67,5) for r=0,1 do local tb=r==0 and sun or blood local y=76+r*12 if r==1 then pal(10,8) end for i=1,6 do if tb[i]==1 then spr(128,22+i*9,y) end end pal() end if crown(sun) then spr(130,8,76) end if crown(blood) then spr(131,104,88) end print("god mode: "..(GOD and "on" or "off").." (down: toggle)",8,115,GOD and 10 or 5) print(crown(sun) and crown(blood) and "z: normal life   x: ascension" or "z: begin life",14,122,10) end
function drawending() cls(0) print("you step off the wheel",22,40,10) print("no more marks. no more hunger.",14,56,7) print("the gods keep their thrones.",20,66,7) print("you keep the silence after.",22,76,7) print("z: return",48,100,5) end
-- entry
function _init() wph=0 loadsave() state="rebirth" music(0) end
SU={level=updchoice,modal=updmodal,tally=updtally}
function _update60() fr+=1 if state=="rebirth" then if btnp(3) then GOD=not GOD loadsave() elseif btnp(5) and crown(sun) and crown(blood) then startlife(true) elseif btnp(4) then startlife(false) end elseif state=="ending" then if btnp(4) then state="rebirth" end else local f=SU[state] if f then f() else updateplay(1/60) end end end
function _draw() pal() if state=="rebirth" then drawrebirth() return end if state=="ending" then drawending() return end drawworld() drawhud() if state=="level" then drawchoice() end if state=="modal" then drawmodal() end if state=="tally" then if diss<1 then for i=1,diss*520 do pset(rnd(128),rnd(128),0) end else drawtally() end end end
__gfx__
000070007000700000000aaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000070077700700000000aaa8aaa000000000000c000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000
000777777777770000000aaaaaaa00000000000cac000000000000000000000000000000000000900000000000a0000a0000000000000aaa0000077707772277
000777777777770000000004440000000000000cac000000000000000000000000000000000009990000000000aa00aa0000000000aaaaaa0000077707772277
00007707770770000000000777000000000000ccacc00000000000000000000000000000009999990000000000aa00aa000000000aaaaaaa0000007222722227
0000708070807000000000777770000000000cc7a7cc0000000000000000000000000000099994440000000000aaaaaa0000070aaaaaa0000000007222722227
0000770777077000000007778777000000000cc7a7cc000000000000003300000000000099944999000000000aaaaaaa000000aaaaa004440000022222222222
000077770777700000000778087700000000cc77a77cc00000000000033330000000000999999999000000000aaaaaaa00000aa8800440000000222222222222
000007777777000000aaa7788877aaa00000cc7cac7cc00000000000333333000000009949999999000000000999999900000aaa004000000002222222222222
000000777770000000aaa7778777aaa00000ccc7a7ccc0000000000033333300000009994999999900000000099999990000aaa0040000000002222222222222
000002222222000000aaaa77777aaaa00000cc77a77cc000000000003333330000009994999999990000000000000fff000aaaa0400000000002222222222222
000222222222220000000077776000000000cc77a77cc00000000000033333330000994999999999000000000000ffff000aaa04000000000002222222222222
00222222222222200000007676600000000cc77cac77cc000000000033333333000099499999999900000000000fffff000aaa04000000000002222222228888
00722222222227200000007676600000000cccc7a7cccc00000000333333333300099499999999990000000000ffffff00aaa040000000000000222222888882
00722222222227200000007676600000000cc777a777cc00000033333333333300999499999999990000000000fff1ff00aaa040000000000000022288888882
007222227222272000000076a6600000000cc777a777cc00000333333333333300099499999999990000000000ffffff00aaa040000000000000002288888882
02722222722227220000007676600000000cc77cac77cc00000000fffff000000000000000000000000000000aaa000000000000000000000000000000000000
027227777777272200000076766000000000ccc7a7ccc00000000fffffff0000000000000000000000000000aaaaa000000000000000000000900000000000aa
072222227222227200000076766000000000cc77a77cc0000000fffffffff00000000000000000000000000aaaaaaa00000000000000000000990a0000000aaa
07222222a222227200000076766000000000cc77a77cc000000f444fff444f0000000000000000000000000aaa8aaa0000077777777777000089000900000a0a
072227788877227000000076a66000000000cc7cac7cc000000fffffffffff0000000000000000000000000aaaaaaa0000777777777777700999900900000aaf
0722222282222270000000767660000000000cc7a7cc000000fff0fffff0fff0000000000000000000000000aaaaa00000777778887777709900000000000aaf
072222227222227000000076766000000000ccc7a7ccc00000fffffffffffff00000000000000000000000000aaa000007777788888777770000000000000aa7
7072277777772727000000767660000000000cc7a7cc000000fffffffffffff00000001000100000000000000040000007777888888877770000000000000aa7
00222222722222200000006676600000000000ccacc0000000fffff222fffff000000000000000000000000010f000007a7778888888777a0a00000000000aa7
0022222272222220000000667660000000000cccaccc000000ffffff2ffffff00000000000000000000000011141000007777888888877770000000000000aa7
002222227222222000000006660000000000c00cac00c00000ffffff4ffffff00000000000000000000000011141000007777788888777770000000000000aa7
0002222222222200000000066600000000000000a0000000000f4fff4fff4f00000000111110000000000011114100000077777888777770000000000000007a
0002220222022200000000006000000000000000a0000000000f4fff4fff4f0000000000000000000000001111410000007777777777777000900000000000aa
0002200222002200000000006000000000000000a00000000000f444f444f000000000000000000000000011114100000007777777777700099000000000007a
0002000020000200000000000000000000000000a000000000000fffffff00000000000000000000000001111141000000000000000000000990000000000077
000000002000000000000000000000000000000000000000000000fffff000000000000000000000000001a11141000000000000000000009999000000000077
000440000000000000000000000000000000000000000000000000006000600000000000000000000000000000000000eeee0000000000a000099000600000a0
04400444000444440000000000404000000070000007000000000005555555650000000000000000000000aa00e00000eeeee000000000af00000000060000af
0000044404400444000000000049990000007000000700000000060599555556000000000000000000000aaa0e7ee000ee77ee0000000aaa0080000000400aaa
000004440000044400000000009999940007770888777000000000699995555000000000000e000000000a0feee7eeee0ee77ee000000f8f0880000060040f8f
02000444000004440000000009999999000777888887700000000000995556000000000000eee00000000aafeee77eee0ee777ee06000fff0880000060004fff
002204420000044290000000099990f90000088a8a88000000000004400600000000000000eee00000000aafeee7777e0ee7777e060000ff88880000060004ff
00002492000024920900099999999ff8000008888888000000000004400000000000000000dedd0000000aa70ee7777000e777ee006440110008800000400041
00004992002249920409999999999fff00000088888000000000000440000000e000ddddddddd8d000000aa70ee777e0000ee7ee0000044400a0000000044994
000049920200499200999499999999f000000228882200000000000440000000e0ddddddddddddd200000aa70ee777e00000e000000009990009000000000499
02222992022229920099999999999900000022222222200000000004400000000ddddddddddddd7000000aa700eeeee000000000060009990099000000000949
00004992020049920099994949999900000222292222220000000004400000000dddddddddddd07000000aa700eee00000000000060004440099000000000994
000044920022449200099999999990000002222292222200000000044000000000ddddddddd0000000000777000e000000000000006441110999900000000111
0000244200002442000049999994040000202229292220200000000440000000000ddddddd000000000007770000000000000000000001110000990800000111
0022044200000442000040400004040000000229222200000000000440000000000d00d00d0000000000077a0000000000000000000011110000000800001111
0200000200000002000040400004040000000022222000000000000440000000000d00d00d000000000007a70000000000000000000011110000008800001111
00000000000000000000404000040400000000022200000000000004400000000000000000000000000000000000000000000000000011110000088800001111
000000a000000000000000dd000000000000000000000008000000000000000a000000660080000000000000000000000000000000000000000000000a700000
000000af0000004400000dd800000000000000770000555800006666000000070000066600880000066666660000004400000000000000000000aaaa007a0000
00000aaa0000044400000ddd0000000c000007770000558800066666000000770000666600088888053555550000044400000000000000000000a00000070000
00000f8f00000f0f000000dd0000000000007777000055550006666600a0007c0000660600088888055553550000044400000000aaaaaaaaaaaaa0000007a000
00000fff00000fff0000000d00000bbb00007077000055ff00666666000007cc00006660000888880055011100000f0f00fffffa999999999999aaaa0007a000
000000ff000000ff0000000d0c00bbbb0000777700000fff00555555000077cc0000660020088a880055011100000fff004444aa000000000000a00000770000
0000000100000011000000dd000bbbbb00000767005558ff0056116600007ccc00006660220888880055011a000000ff004444a0000000000000aaaa077a0000
000044440000001100000dee00bbbbbb00000767055555ff005666660007711c0000666602288787005501190000cccc004444a000000000000000000a000000
64440099000000110000ddee00bbbbbb00000767055555ff0056656600077ccc0060666602208888005501910000cccc0044444a00999499999999f00880880a
00000099000001110000deee00bbb0bb0000000605552225005665660a007cc1000666660020888800550111000ccccc0044444a009999999999990088888880
00000044000001110000deee00bbbbbb00006666005522250056661600007ccc000655550020888800550111000c44440044404a009999494999990087888880
00444411000001110000deee00bbb0bb000000060000222a005666660000077c000666660000088800550000000c05500044444a000999999999900088888880
64000011000001110000deee00bbb0bb00006666000022250055611100000777000665550000888805555555000f05500044444a000409999990004008828800
00000111000011110000ddee00000b00000000060000222500066666000000cc000666660000888805555555000005500044404a000400040040004000888000
000001110000111100000dee000000000000666600002555000666660000000c000660660000080055555555000005500044444a000400040040004000080000
0000011100001111000000d0000000000000000000000550000555550000000c0066000600000800666666660000000000000000000400040040004000000000
0009900000080000a00aa00a80088008000cc0007700007700070000000006000000000000080000000aaa00088088007777777700000000aa000aa044444440
0900009000080000aaaaaaaa2282282200cccc00777007770007000000040600000000b00800008000a770008888888055555555000ee0000aa0aa0004444400
000aa00000888000aaaaaaaa222222220c7cccc00777777000076000004006000000b00b0099090000aaaaaa8e88888056555565000ee00000aaa000004a4000
90a7aa0908888800aaaccaaa22288222ccccccc0000770000007600004400600700b00b0000aa0000aaaaaa088888880555555550eeeeee0000a0000000a0000
90aaaa0908888800aaaaaaaa222222220ccccc000006600000aaa0000440060070b07000809aa0900aaaaa0008888800055555500eeeeee000aaa000004a4000
000aa00008788800000000000000000000ccc000077777700004000000400600700b00b000900900aaaa00000088800005555550000ee0000aa0aa0004a4a400
09000090008880000000000000000000000c00007770077700040000000406000000b00b0800908000a000000008000000555500000ee000aa000aa044444440
0009900000000000000000000000000000000000770000770009000000000600000000b0000000000a0000000000000000055000000000000000000000000000
0770077000000009000000004444444444444444444444444444444400000000000000000000d00000000cc00000011100000dde00000000000000880000d000
088008800000009800888800ffffffffffffffffff4444ff44ffffff0000000000e0a000000d00000000cccc0000011100000dee0000000066666688000d0000
088008800000098808888880ffffffffff4444ffff4224ff44ffffff00b00b000b0b0b00000d0000000cc7c00000011100000dee0aa00aa055555558000d0000
088008800000989808989890f7ffffffff4aa4ffff4224ff44ff7fff00b03b0000b7b00000d0000000cc00000000011100000dee000000000550000000d00000
088008800009888888888888ffffffffff4444ffff4444ff44ffffff0b3b03b00b0b0b0000d000000cc000000000111100000dee0000000005500000edd00000
008888000098888898989898ffffff7fff4aa4ffff444aff44ffffff0b3b03b0000000000e000000cc0000000000111100000dde000000000550010000000000
000880000989889888888888ffffffffff4444ffff4444ff44ffffff000000000000000000000000c000000000000011000000de000000000550000000000000
000000009888888822222222ffffffffffffffffff4444ff44ffffff0000000000000000000000000000000000000000000000dd000000005555000000000000
000000000000000000000000003333333333333300000eeeeeee000000ffffff000000000000000007777770003333fffffffffffffffefffffeffff00000000
0000000009000090000000000033333333333333000ee0fffff0ee00000fffff000000000000000007000070000333fffffffffffffffefffffeffff00000000
00b0b0b09990099900000000033333333333ffff00e0fffffffff0e00000ffff0000000000000000070660700033333fffffffffffffffefffefffff00000000
00b0b0b009099090003b30b0033333333fffffff00fffffffffffff000000fff00000000000000000700007003333333ffffffff0ffffffeeeffffff00000000
0bbbbbbb009999000bbbbb0b03333333ffffffff0fffffffffffffff00011111000007070707000007060070333333333fffffff0fffffffffffffff00000000
00a0a0a000099000033b33b00333333fffffffff0ffffffeeeffffff0071111a000007777777000007000070333333330003ffff00fffffffffffff000000000
00b0b0b004040040003b3000033333ffffffffffffffffe7ffefffff0011111a000007777777000007777770033333300000000000e0fffffffff0e000000001
000000000000000000303000003333fffffffffffffffefffffeffff0011111a0000077767770000000000000033330000000000000ee0fffff0ee0000000001
0011111a000076666666000000000aa700000aa7000000000000000000000000000000000000a00000aaaa0077000077000cc000a000000a0000000000000060
0111111a000666666661500000000aa700000aa700000000000000000000000000000000004444440a0000a078800887000cc000000ee0000000006666667660
0111111a000666555516500000000aa700000aa70000000000000000000000000000000000444444a000000a0888888000c77c0000ee7e000000066777776666
1111111a000666655616500000000777000000770000000000aa0000000888008008880000aaaaaaa000000a08e8888000cccc000e2ee2e00000667777666600
1111111a00066655556650000000077700000077000000000aa0aaaa0087777888777780000000000a0000a0008888000cccccc0e2eaa2ee0006777776600000
1111111a000666666663500000000777000000070000000aaa0aa00000877888888877800000000000aaaa00000880000cc7ccc0eeeeeeee0067666660000000
1111111a00535555555555000000077700000007000000aaaaa004440877788888887778000aaaaa000000000000000000cccc003bbbbbb30466660000000000
1111111103b0555555550b30000007770000000700000aa8a00040000877888888888778000aaaaa000000000000000000000000bbb00bbb4006000000000000
00000aaa000000008777888888888777a00aa00a770000770008800000006000070000000022220000ffff000000000000000000000000000000000000000000
0000aa000400000008778888888887780a0000a077700777008888000000666677000000022220000ffffff00000000000000000000000000000000000000000
000aaaa0400000000877788888887778000aa0000777777000888800000066760555555022200000ff4ff4ff0000000000000000000000000000000000000000
000aaa0400000000008778888888778000aaaa000088880008888880000046660555555022000080ff4ff4ff0000000000000000000000000000000000000000
000aaa040000000000877778887777800099990000800800088288800000400605595550222000000ffffff00000000000000000000000000000000000000000
00aaa04000000000000888888888880000999900000000000088880000040000055595500222200000ffff000000000000000000000000000000000000000000
00aaa040000000000000000000000000444444440000000000088000000400000055550000222200000440000000000000000000000000000000000000000000
00aaa040000000000000000000000000333333330000000000000000004000000055550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0004000001514000400000401001000400100000000000000400000000000004000401040000010000150000000000000001010000000031040030000401000000060000400100100000010050000101000000000000000000001010000000004000410001000000001000004004000400000000100000400010001045010000
10400040000140000000001400000010000040000010000000100000401000000c0010004000000040001040010c101000000004000000004004000010000000011000000000000002000001000c0000104000004000010000000000000000000000000000000000000004000000000010000001010000000440000040000080
0000004000000000110541004004001000054100010101001000010010000100004000001440001000000000000100400000000000001050000000000000001040000004000004000340010000000000000000000100000010000000010000410104100000000000000000000000000000000034400050000000000000400010
0010100044211100040004000004400000000000000140000118410000000010050000400400000010010000004000900000000043000044014000000004001000000400000080040014c000000000040000000000000000000000000100010704800004001110001000000004401101010000c0000000000100000001000000
0004000004000040010000000004005040000000001000000100000411100100044040000100000001041000003000010004005010000000000000050000005400000000010000000040100004005000011001000000010400404001004000040500000001000010100040000000430000804200008100000400400010400010
00404000004000000000100000000001100000000011040000000000000010200000000000c010000000020000400010000051100300000000000000000010000018000004110000001000000000001000900000110000000010110000003000400140000000100101010000000400010040c040000080043000000000100000
0040000000001004001000000080400000000000000000000004100100000400100000404000000100000400000404400100004000104000000501110000404000040100040000000001000000040001400400000000010000000440000000004004100004002010000000041040001004000000000000000000100000000000
0a08000010000301000014000000000004000001004000000014010000002000001010100010040000000105908110000000000100000000400010000000000000000400800010000040000400000021000001000000000004000041010000004100000110050000010000c40000000000400104041200400100040000000400
00004000000000040501000004001000000010003000100410000044010000000000140400040000000010040000010100100000001010040000400400000002400040004014400000000000000000001040000000404100001000000000000000010001000d4000041000000000000007000001000000000000030004000000
0000000400000200000000000000100800000410000000000001000000400000000000010000000004000001400000000003000000000000000000044000400401020000040008004040100000000400400000000010080000000000000404004000070000001100100001400400400020004000000100100040004000100044
00000000000004000000000100040000100041100000c000000000000004010004000000500410000200000041141401000208000040000000000000001000000010004000010010000000000000000000000000000000041000000d100000144000000000001000000000514410010000400000100000000000000180400000
04000004000000010401000100000000400000104040000001000004002044001000000000010044040300004001000000000000003000400400001500000101000000002000000100010040400000000100000000440000001000000000100000004000080200010003000000408010000c1040000000101040000070000000
2010300100010010010001004010104010000030000400000040400000000104000480007404000000004004000000000005000004004000000000001000000000040004000010101004000010000000000000800004010004000001000000000100000010003000000510000000040040000004005100000000000000081000
0000004000000004420000200404008404010100000000011014001440100001010000001040018110040000000000000014010100000000001000120100000000000000000000002000000010500000404008400044004040000000001009000010000000000000000000000000210000000000000000004000010800030000
0000543100000000004000000000040001000004000000000504000010000100410000000000000001040000500000800000000000040000004001000000000000000000000200000800000000000010100000040010000000140001000010004101000180010400000001010000004001300000044410000000000000441000
000040000440100000040000004400100000000040004014101001000001000010010040001000d0000c0000100080000404001000004000000400000000011000000000000080000000000000000134000004001300000400100000101015400040000100000014101040001040100000000000000000010000000041200000
1004000000040000000010000100000c40000004000010001c00000000000000000004000000400044510100000040000410000000000000000440040000000000000000100100000000008000000010040010810000010040000000400441040000001000000000100420400000100040004001040000000004400044000000
4005004050000110000140c00040000010000001000000400000115000900040000140400000044004114100000000010440400000000000000000000000414000010010000101010000200010040000000000400100000000004000048000004000010000000014401008400000010c40140400010110000011001001000000
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
