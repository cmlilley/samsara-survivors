pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- samsara survivors: data-driven rewrite (entity modes, boss sequencer, event places)
fr=0
GN={"narak","vora","ferrox","aurel","kharun","lumara","the judge"}
FN={"soul mote","deva","monk","animal","hungry ghost","hellborn","asura","enlightened"}
FHP=split("60,140,120,105,90,75,150,150")
FSPD=split(".95,1.2,1.15,1.1,1.05,1,1.25,1.25")
FDMG=split(".9,1.25,1.15,1.1,1.05,1,1.35,1.35")
FH=split("135,110,133,72,129,132,106,76") FCAP=split("3,8,6,5,4,4,8,8")
EN={"slime","rat","skeleton","soldier","guardian","wisp","ghost","big slime","brute","turret"}
-- foe rows: hp,spd,dmg,ess, mode, a,b,c,d,e,pspd
-- modes: 1 pulse, 2 weave, 4 shooter, 5 melee, 6 phase
-- shooter a=proj b=cd c=pdmg d=band-in e=band-out; melee a=jab-dmg b=jab-cd
ETS={"6,.35,4,1,1,0,0,0,0,0,0,.8,.4375,0,0,0,8","4,.8,3,1,2,0,0,0,0,0,0,0,0,0,0,0,8","8,.4,4,3,0,bone,1.6,5,62,48,1.7,0,0,0,0,0,8","26,0,6,6,0,bolt,1.9,6,0,0,1.1,0,0,0,0,0,8","5,.5,6,3,1,ember,1.7,5,0,0,1.4,2.4,.5,.3,0,0,8","7,.55,0,2,1,bolt,2,4,0,0,1.2,.8,.4375,0,0,0,8","220,.28,18,45,0,slash,1,10,0,0,1.5,0,0,0,24,0,16","20,0,0,6,0,bolt,1.5,5,0,0,1.8,0,0,0,0,0,8"}
ET={} for i=1,10 do ET[i]=split(ETS[i]) end
FSN=split("138,104,137,131,143,130,139,140")
FSF=split("0,0,0,0,0,0,0,0") FFA=split("73,74,75,77,96,97,98,99")
FDS=split("0,135,0,110,0,133,0,72,0,129,0,132,0,106,0,76") MIR=split("1,6,5,4,3,2,8,7")
FDA=split("64,65,66,67,68,69,70,71")
PT=split("5,6,4")
PKS={ess=169,mark=176}
function ucap(i) return (i==2 or i==4) and 0 or min(UM[i],asc and 8 or FCAP[form]) end function mkcarry() carry=0 for i=1,10 do if saved[i]>0 then carry+=1 end end end
-- boss patterns per god, split rows: mv,mind,cd, akind, params...
-- akind: 1 pend(p1: 2 dash/3 swipe, p2 delay, p3 dash-spd)
-- 3 fan(n,step,sp,dm) 4 zones(p1: 1 patches/2 beams)
-- 5 set(p1: 1 vac/2 kwaves)
BPS={".6,36,2.6,4,1",".22,46,3.5,5,1",".5,0,2.6,1,2,.6,4",".45,42,1,3,3,.1,2,7","0,0,2.4,5,2",".3,42,3.2,4,2",".45,30,0,0"}
BP={} for i=1,7 do BP[i]=split(BPS[i]) end BTS={"0,0,0,0,0,0,0,0,0,0,0,0,0,0","0,0,0,0,0,3,2,0,0,0,0,0,0,0","0,0,0,0,0,0,0,0,0,0,0,0,0,0","0,0,0,8,5,0,0,0,0,0,0,8,0,1","3,20,8,0,0,0,0,0,.25,0,0,0,0","0,0,0,0,0,0,0,0,0,0,0,0,0,0","0,0,0,0,0,0,0,50,3,0,0,0,0,0"} DBK=split("0,70,35,0,-35,-70,0")
BSP=split("192,194,196,198,200,202,204")
BFR=split("0,2,4,6,8,10,12")
JACT={bolt=split("0,0,1.4,3,5,.06,2,7"),melee=split("0,0,1.8,1,3,.5")}
UN={"power","bolt","spread","damage","speed","max hp","armor","regen","cooldown","magnet"}
UI=split("178,179,180,181,182,183,184,185,186,187")
UM=split("8,5,4,5,5,5,5,5,5,5")
PL={{x=128,y=600},{x=640,y=120},{x=620,y=660}}
-- utils
function cl(v,a,b) return mid(a,v,b) end
function dst(x1,y1,x2,y2) local dx,dy=(x2-x1)/16,(y2-y1)/16 return sqrt(dx*dx+dy*dy)*16 end
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

function loadsave() cartdata("samsara_v1") if dget(36)~=777 then for i=0,63 do dset(i,0) end dset(36,777) dset(32,100) end sun={} blood={} saved={} for i=1,6 do sun[i]=dget(i) blood[i]=dget(6+i) end for i=1,10 do saved[i]=dget(39+i) end mkcarry() bank=dget(31) bank2=dget(33) lastk=dget(32)-100 lives=dget(35) end
-- stats



function recalc() local bh=asc and 150 or FHP[form] local bd=asc and 1.35 or FDMG[form] maxhp=bh+bmax+18*U[6] hp=min(hp,maxhp) dmgs=bd*(form==6 and 1.05 or 1) spd=1.4*FSPD[form]*(1+.09*U[5]) pdmg=10*dmgs*(1+.22*U[1]) bdmg=pdmg rng=20+3*U[1] arcw=1/6+U[3]/24 mag=(16+10*U[10])*(form==5 and 2 or 1) essm=form==5 and 1.2 or 1 armor=U[7] regen=(form==2 and .5 or form==8 and 1 or 0)+.6*U[8] end
function unlock(w) if w==8 then bank2=1 dset(33,1) else bank=1 dset(31,1) end end function pform(k) return bank+bank2==0 and 0 or bank==0 and 8 or bank2==0 and 7 or k>=0 and 8 or 7 end function ladder(k) return k>=60 and 2 or k>=20 and 3 or k>=-19 and 4 or k>=-59 and 5 or 6 end
function kadd(v) karma=cl(karma+v,-100,100) end
function heal(v) hp=min(maxhp,hp+v) end
function gainxp(v) v*=essm ess+=flr(v) xp+=v while xp>=need do xp-=need lvl+=1 lvlq+=1 need=5+4*lvl+lvl*lvl end end
-- life setup
function startlife(a) asc=a foes,pp,ep,pk,zn,ac,B={},{},{},{},{},{},nil U={} for i=1,10 do U[i]=0 end lvl,xp,need,ess,kills,bmax=1,0,10,0,0,0,0 karma=lastk hp,px,py,face,pinv,pcd,bcd,avt,tsec,tmin,df,lvlq=1,384,384,.25,0,0,0,0,0,0,0,0 local pf=pform(karma) form=pf>0 and pf or asc and ladder(flr(karma)) or lives==0 and 1 or ladder(flr(lastk)) for i=1,10 do U[i]=min(saved[i],ucap(i)) end U[1]=min(ucap(1),saved[1]+saved[2]+saved[4]) if dfm>0 then form=dfm karma=DBK[dfm] end lives+=1 dset(35,lives) recalc() hp=maxhp spawnt,markearned=1,0 won=false marktxt,crownnote="","" nextinn,fedt,pacc,ascidx,ascnext=6,0,0,1,20 lastr=0 cht=25 for P in all(PL) do P.done=false P.ch=0 P.on=false end state="play" ban(asc and "ascension life" or FN[form]) music(asc and 3 or 1) if dbs>0 then dolock() spawnboss(dbs,lockform) end end
-- drawing helpers
function drw(n,x,y,w,h,m,f) if m==4 then spr(n,x-16,y-16,4,4) return end local sx,sy=(n%16)*8,flr(n/16)*8 if m==0 then sspr(sx,sy,8,16,x-w/2,y-h/2,w/2,h) sspr(sx,sy,8,16,x,y-h/2,w/2,h,true) elseif m==1 then sspr(sx,sy,16,16,x-w/2,y-h/2,w,h,f) elseif m==2 then spr(n,x-16,y-16,2,4) spr(n,x,y-16,2,4,true) end end
function aura(x,y,f) local o,m,c=9,10,7 if f==7 then o,m,c=8,9,10 end for h=0,20 do local t=h/20 local yy=y+9-h local r=11*(1-t*.75)*(.8+.25*sin(fr*.11+h*.55)+.12*sin(fr*.23+h*1.3)) if r>1 then line(x-r,yy,x+r,yy,o) end if h<15 and r*.55>1 then line(x-r*.55,yy,x+r*.55,yy,m) end if h<8 then line(x-r*.25,yy,x+r*.25,yy,c) end end end
function drawform(f,x,y,fa,at,m,pv) local nf=fr%32<16 local fx,fy=cos(fa),sin(fa) local ff=fx<0 local n=FDS[2*f] if m then y+=((f==2 or f==6) and sin(fr*.07)*2.5 or sin(wph)*1.1) end if f>=7 then aura(x,y,f) end if nf then n=FDA[f] end drw(n,x,y,16,16,FDS[2*f-1],ff) if f==3 then local sx=x+(ff and -7 or 7) line(sx,y-6,sx,y+9,4) circfill(sx,y-7,1,10) end if f==2 or f==6 then for i=0,2 do local a=fr*.04+i/3 pset(x+cos(a)*12,y+sin(a)*5,f==2 and 10 or i%2==0 and 9 or 8) end end if pv and form==2 then circ(x,y-13,4,10) end end


function addpick(k,x,y,v) add(pk,{k=k,x=cl(x,10,758),y=cl(y,10,758),v=v or 1}) end
function spawnpos() local a=rnd() local r=95+rnd(55) return cl(px+cos(a)*r,10,758),cl(py+sin(a)*r,10,758) end
function spawnfoe(t,x,y) if not x then x,y=spawnpos() end local b=ET[t] local e={k=t,x=x,y=y,face=.25,kx=0,ky=0,burn=0,tm=rnd(),acd=.5+rnd(1.5),hp=b[1]*(1+.2*tmin),dmg=b[3],ess=flr(b[4]*(1+.25*tmin)),scale=b[16],r=b[17],w=b[16]>0 and b[16] or 16,h=16} add(foes,e) return e end
function rpick(t) return t[flr(rnd(#t))+1] end
function pickn(p,c) local o={} for i=1,c do local j=flr(rnd(#p))+1 add(o,p[j]) p[j]=p[#p] p[#p]=nil end return o end
function picktype() local m=tmin if m==0 then return rnd()<.12 and 3 or flr(rnd(2))+1 end local o={1,1,2,2,3} for i=1,min(3,m) do add(o,PT[i]) end return rpick(o) end
function addep(x,y,a,sp,d,k) add(ep,{x=x,y=y,dx=cos(a)*sp,dy=sin(a)*sp,d=d,k=k,t=0,life=2.5/sp}) end
function hurt(d,u) if u then if hp>0 then hp-=d end return end if pinv>0 or hp<=0 then return end sfx(42) hp-=max(1,d-armor) pinv=.5 end
function dmgx(t,d,kx,ky,src) if t.hp<=0 then return end if t.god==4 and t.shield then d*=.25 end t.hp-=d if t.k then t.kx+=kx t.ky+=ky end if form==6 and (t.god or src==1) then t.burn=3 end if t.god and t.hp<=0 then killboss() end end
function killfoe(e) kills+=1 addpick("ess",e.x+rnd(9)-4,e.y+rnd(9)-4,e.ess) if e.k==1 and rnd()<.3 then spawnfoe(picktype(),e.x,e.y) end if e.k==7 then pendingrival=true addpick("chest",e.x,e.y) end end
function sweepfoes() for e in all(foes) do if e.hp<=0 then killfoe(e) del(foes,e) end end end
function killboss() sfx(43) addpick(asc and "chest" or "mark",B.x,B.y) if B.judge then pendingfinal=true B=nil return end if asc then ascidx=B.god+1 B=nil local nf=karma>=100 and 8 or karma<=-100 and 7 or form<7 and ladder(flr(karma)) or form if nf~=form then form=nf recalc() ban("you become: "..FN[form]) end if abs(karma)>=100 then unlock(karma>0 and 8 or 7) end return end markearned=0 if B.form=="feral" then marktxt="no mark: feral god" else local tr=B.form=="trial" local tb=tr and sun or blood local was=crown(tb) tb[B.god]=1 dset((tr and 0 or 6)+B.god,1) markearned=tr and 128 or 129 marktxt=(tr and "sun mark: " or "blood mark: ")..GN[B.god] if not was and crown(tb) then crownnote=tr and "crown of heaven earned" or "crown of hell earned" unlock(tr and 8 or 7) end end B=nil won=true end
-- combat
function nearT(x,y,r,ph) local bt,bd=nearfoe(x,y,r,nil,nil,ph) local bk=bt and "f" or nil if B then local d=dst(x,y,B.x,B.y) if d<bd then bk,bt,bd="b",B,d end end return bk,bt,bd end
function arhit(r,d,src) local kb=src==1 and 1.5 or 0 for e in all(foes) do if e.hp>0 and dp(e)-e.r<=r then local a=af(e) if adf(a,face)<=arcw then dmgx(e,d,cos(a)*kb,sin(a)*kb,src) end end end if B and dp(B)-16<=r and adf(af(B),face)<=arcw then dmgx(B,d,0,0,0) end end
function doswing(tg) face=af(tg) avt=.16 arhit(rng+3,pdmg,1) end
function firebolt(tg) local a=af(tg) local n=1+U[3] for i=1,n do local aa=a+(i-(n+1)/2)*.035 add(pp,{x=px,y=py,dx=cos(aa)*3.2,dy=sin(aa)*3.2,d=bdmg,life=(rng+108)/192}) end end
function attacks(dt) pcd-=dt bcd-=dt avt=max(0,avt-dt) local cdm=max(.4,.9^U[9]) if pcd<=0 then local bk,tg,d=nearT(px,py,9999,true) if tg then local ed=d-(bk=="b" and 16 or tg.r) if ed<=rng then doswing(tg) pcd=.55*cdm end end end if bcd<=0 then local tg,bd=nil,rng+92 for e in all(foes) do if e.hp>0 then local d=dst(px,py,e.x,e.y) if d<bd and d-e.r>rng then tg,bd=e,d end end end if not tg then local _,t2=nearT(px,py,rng+92,true) tg=t2 end if tg then firebolt(tg) bcd=.9*cdm end end end
function updpp(dt) for p in all(pp) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=false if B and dd(p,B)<18 then dmgx(B,p.d,0,0,0) dead=true else local hit=nil for e in all(foes) do if e.hp>0 and dd(p,e)<e.r+2 then hit=e break end end if hit then dmgx(hit,p.d,0,0,1) dead=true end end if dead or p.life<=0 or abs(p.x-384)>392 or abs(p.y-384)>392 then del(pp,p) end end end
function updep(dt) for p in all(ep) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=p.life<=0 if dp(p)<5 then hurt(p.d) dead=true end if dead then del(ep,p) end end end
-- enemies: one update, mode-dispatched from the ET row
function movefoe(e,tx,ty,sp) local d=dst(e.x,e.y,tx,ty) if d>1 then local a=ang(tx-e.x,ty-e.y) e.x+=cos(a)*sp*df e.y+=sin(a)*sp*df e.face=a end end
function updfoe(e,dt) e.tm+=dt if e.burn>0 then e.burn-=dt e.hp-=2*dt end e.x=cl(e.x+e.kx*df,8,760) e.y=cl(e.y+e.ky*df,8,760) e.kx*=.8 e.ky*=.8 local r=ET[e.k] local sp=r[2] local d=dp(e) e.acd-=dt local jr=e.r+12 if e.acd<=0 and r[15]>0 and d<=jr then hurt(r[15]) e.acd=r[7] elseif e.acd<=0 and r[8]>0 and d<=96 then local a=ap(e)+rnd(.05)-.025 e.face=a addep(e.x,e.y,a,r[11],r[8],r[6]) e.acd=r[7] end if sp>0 then local pu=1 if r[5]==1 then pu=e.tm%r[12]<r[12]*r[13] and 1 or r[14] end if pu>0 then local tx,ty=px,py if r[5]==2 then local a=ap(e) tx,ty=px+cos(a+.25)*14,py+sin(a+.25)*14 end local go=false if r[15]>0 then go=d>jr-2 elseif r[9]>0 then if d>r[9] then go=true elseif d<r[10] then go=true tx,ty=2*e.x-px,2*e.y-py end else go=d>2 end if go then movefoe(e,tx,ty,sp*pu) end end end end
function spawnboss(g,fm) local x=cl(px+(rnd()<.5 and -80 or 80),30,738) local y=cl(py+(rnd()<.5 and -60 or 60),30,738) B={tm=0,acd=1,tele=0,dash=0,vac=0,ring=3,burn=0,waves=0,god=g,tr=split(BTS[g]),form=fm,b1=BSP[g],b2=BFR[g],x=x,y=y,hp=g==7 and 2000 or fm=="feral" and 1200 or 1600} B.mh=B.hp if g==7 then B.judge=true B.mode=U[3]>=U[1] and "bolt" or "melee" end ban(GN[g].." ("..fm..")") music(3) end
function bossfire(a,sp,d,k) addep(B.x,B.y,a,sp,d,k or "ember") end
function radial(n,sp,dm,off) local ra=off or rnd() for i=0,n-1 do bossfire(ra+i/n,sp,dm) end end
function fan(a,n,st,sp,dm) for i=-(n-1)/2,(n-1)/2 do bossfire(a+i*st,sp,dm) end end


function doact(A,a) local ak=A[4] local p1,p2,p3,p4=A[5],A[6],A[7],A[8] if ak==1 then B.tele=p2 B.pend=p1 B.ptm=p2 if p1==2 then B.dsp=p3 end elseif ak==3 then fan(a,p1,p2,p3,p4) elseif ak==4 then if p1==1 then for i=1,3 do add(zn,{k=1,x=px+(i-2)*22+rnd(13)-6,y=py+rnd(25)-12,r=14,wn=.7,b=4,d=6}) end else for i=-1,1 do add(zn,{k=2,x=cl(px+i*24,8,760),w=8,wn=.8,b=1.5}) end end elseif ak==5 then if p1==1 then B.vac=2 else B.waves=3 B.wcd=0 end end end
function updboss(dt) if not B then return end B.tm+=dt if B.burn>0 then B.burn-=dt B.hp-=2*dt if B.hp<=0 then killboss() return end end B.tele=max(0,B.tele-dt) local d=dp(B) local a=ap(B) local sm=B.p2 and 1.4 or 1 local g=B.god local tr=B.tr local busy=false if tr[1]>0 then for i=0,tr[1]-1 do local sa=B.tm*.4+i/tr[1] if dst(px,py,B.x+cos(sa)*tr[2],B.y+sin(sa)*tr[2])<7 then hurt(tr[3]) end end end if tr[4]>0 then local sh=B.tm%tr[4]<tr[5] B.shield=sh if sh and not B.tur then B.tur=true for i=-1,1,2 do spawnfoe(tr[12],B.x+i*26,B.y+10) end end if not sh then B.tur=false end end if B.waves>0 and B.dash<=0 then B.wcd-=dt if B.wcd<=0 then fan(a,5,.06,2,7) B.waves-=1 B.wcd=.25 end end if B.vac>0 then B.vac-=dt local va=af(B) px+=cos(va)*1.1*df py+=sin(va)*1.1*df busy=true if B.vac<=0 then fan(a,tr[6],.12,2,7) for i=1,tr[7] do spawnfoe(1,B.x+rnd(21)-10,B.y+rnd(21)-10) end end end if tr[8]>0 and not B.p2 and B.hp<B.mh/100*tr[8] then B.p2=true B.b1=206 B.b2=14 ban("the wheel breaks") end if B.p2 then B.ring-=dt if B.ring<=0 then radial(12,1.5,7,0) B.ring=tr[9] end end local P=BP[g] if B.dash>0 then B.x+=B.dvx*df B.y+=B.dvy*df B.dash-=dt elseif not busy then local mv=P[1] if mv>0 and d>P[2] then movefoe(B,px,py,mv*sm) end end B.acd-=dt if B.acd<=0 and not busy then local A=P if g==7 then A=JACT[B.mode] end if B.shield or B.dash>0 or B.waves>0 then A=nil end if A and A[4]>0 then doact(A,a) B.acd=A[3] end end if B.pend then B.ptm-=dt if B.ptm<=0 then local p=B.pend B.pend=nil if p==2 then local da=ap(B) local sp=min(B.dsp,(d+8)/21) B.dvx,B.dvy=cos(da)*sp,sin(da)*sp B.dash=.35 elseif p==3 then if d<48 then hurt(18) end end end end B.x=cl(B.x,16,752) B.y=cl(B.y,16,752) end
function spawnactor(x,y) local a={x=x,y=y,hp=3,inv=0,a=rnd(),dead=false} add(ac,a) return a end
function killactor(a,m) if a.dead then return end a.dead=true if m then kadd(-9) ban(m) else kadd(-3) ban("an innocent has fallen -3") end end
function updactors(dt) for a in all(ac) do a.inv=max(0,a.inv-dt) local fe=nearfoe(a.x,a.y,26) if fe then local fa=ang(a.x-fe.x,a.y-fe.y) a.x+=cos(fa)*.9*df a.y+=sin(fa)*.9*df else a.x+=cos(a.a)*.45*df a.y+=sin(a.a)*.45*df end if abs(a.x-384)>378 or abs(a.y-384)>378 then a.dead=true kadd(2,false) ban("an innocent passed safely +2") end if not a.dead and a.inv<=0 then for e in all(foes) do if e.hp>0 and dd(a,e)<10 then a.hp-=1 a.inv=.8 if a.hp<=0 then killactor(a) end break end end end if not a.dead and dp(a)<14 and btnp(5) then killactor(a,"you slew an innocent -9") end if a.dead then del(ac,a) end end end

function addupgrade(i) U[i]+=1 recalc() if i==6 then heal(12) end end

function placefx(chan) if chan then kadd(8,false) ban("prayer heard +8") else kadd(-8,true) local ow={} for i=1,10 do if U[i]>0 and U[i]<ucap(i) then add(ow,i) end end if #ow==0 then bmax+=12 recalc() heal(12) ban("+12 max hp") else addupgrade(rpick(ow)) ban("free upgrade") end ban("shrine smashed -8") end end
function places(dt) for P in all(PL) do if not P.done then if dp(P)>=26 then P.arm=true P.ch=0 P.on=false elseif P.arm then if btnp(5) then P.done=true P.on=false sfx(44) placefx(false) else if btnp(4) then P.on=true end if P.on then P.ch+=dt heal(maxhp*.1*dt) if P.ch>=2 then P.done=true P.on=false sfx(44) placefx(true) end end end else P.ch=0 end elseif dp(P)<26 then heal(maxhp*.04*dt) end end end
function dolock() lockform=karma>=30 and "trial" or (karma<=-30 and "war" or "feral") lockgod=1 for i=1,6 do local need=sun[i]==0 if lockform=="war" then need=blood[i]==0 elseif lockform=="feral" then need=need or blood[i]==0 end if need then lockgod=i break end end ban(GN[lockgod].." approaching") for i=1,6 do spawnfoe(picktype()) end end
function events(dt) if tmin>lastr then lastr=tmin for P in all(PL) do if not P.on or P.done then P.done=false P.ch=0 P.arm=dp(P)>=26 end end if not asc then if tmin==1 then spawnfoe(6,104,576) spawnfoe(6,152,624) ban("the roadside shrine wakes") elseif tmin==2 then if form~=1 and form~=4 then spawnfoe(7) foes[#foes].mf=MIR[form] ban("your inverse approaches") end for i=1,6 do spawnfoe(picktype()) end elseif tmin==3 then dolock() elseif tmin==4 and not B then spawnboss(lockgod,lockform) end end end if asc then if not B and ascidx<=6 and tsec>=ascnext then spawnboss(ascidx,"trial") ascnext+=25 elseif not B and ascidx>6 and not judgespawned and tsec>=160 then judgespawned=true spawnboss(7,"asc") end return end nextinn-=dt if nextinn<=0 then nextinn=8 if #ac<5 then local sa=rnd() local na=spawnactor(mid(16,px+cos(sa)*105,752),mid(16,py+sin(sa)*105,752)) na.a=ang(px-na.x,py-na.y)+rnd(.08)-.04 end end cht-=dt if cht<=0 then cht=45 addpick("chest",40+rnd(688),40+rnd(688)) ban("a chest has appeared somewhere") end end
function updpick(dt) for p in all(pk) do local d=dp(p) if p.k=="ess" then if d<mag then local a=ap(p) p.x+=cos(a)*3.5*df p.y+=sin(a)*3.5*df end if d<7 then sfx(41) gainxp(p.v) fedt=0 del(pk,p) end elseif p.k=="mark" then if d<9 then sfx(41) del(pk,p) if won then entertally("boss") return end end elseif p.k=="chest" then if d<10 then del(pk,p) openchoices(3,"chest") return end end end end

function openchoices(n,src) sfx(40) local pool={} for i=1,10 do if U[i]<ucap(i) then add(pool,i) end end if #pool==0 then heal(25) ban("nothing left to learn: healed 25") state="play" return end ch=pickn(pool,min(n,#pool)) chsrc=src sel=1 state="level" end
function navc(c,n) if btnp(0) or btnp(2) then c-=1 end if btnp(1) or btnp(3) then c+=1 end return c<1 and n or c>n and 1 or c end
function updchoice() sel=navc(sel,#ch) if btnp(4) or btnp(5) then local src=chsrc addupgrade(ch[sel]) if src=="level" and lvlq>0 then lvlq-=1 openchoices(3,"level") else state="play" end end end
function setmodal(t,l,o,cb) modal={t=t,l=l,o=o,cb=cb,sel=1} state="modal" end
function docb(cb,s) if cb=="rival" then if s==1 then kadd(12) state="play" else kadd(-12) openchoices(3,"free") end elseif cb=="final" then if s==1 then state="rebirth" else state="ending" end end end
function updmodal() modal.sel=navc(modal.sel,#modal.o) if btnp(4) or btnp(5) then docb(modal.cb,modal.sel) end end
function entertally(r) if state=="tally" then return end won=r=="boss" music(won and 4 or 5) diss=0 saved={} for i=1,10 do saved[i]=(U[i]+1)\2 dset(39+i,saved[i]) end mkcarry() lastk=flr(karma) dset(32,lastk+100) state="tally" end
function updtally() diss+=.015 if diss>=1 and btnp(4) then state="rebirth" music(0) end end
-- main update
function updateplay(dt) tsec+=dt tmin=flr(tsec/15) df=dt*60 bant=max(0,bant-dt) pinv-=dt fedt+=dt local mx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0) local my=(btn(3) and 1 or 0)-(btn(2) and 1 or 0) mvflag=false if mx~=0 or my~=0 then local l=sqrt(mx*mx+my*my) face=ang(mx,my) local sp=spd px=cl(px+mx/l*sp*df,10,758) py=cl(py+my/l*sp*df,10,758) mvflag=true wph+=.14 end events(dt) if state~="play" then return end places(dt) local cap=min(30,8+5*tmin) if not B and not asc then spawnt-=dt if spawnt<=0 and #foes<cap then spawnfoe(picktype()) spawnt=max(.22,1.05-.16*tmin) end end for e in all(foes) do if e.hp>0 then updfoe(e,dt) end end sweepfoes() updboss(dt) updactors(dt) attacks(dt) sweepfoes() updpp(dt) updep(dt) local inz=false for z in all(zn) do if z.wn>0 then z.wn-=dt else z.b-=dt if z.k==1 then if dp(z)<z.r then inz=true pacc+=dt if pacc>=.5 then pacc=0 hurt(z.d*.5,true) end end elseif abs(px-z.x)<z.w then hurt(10*dt,true) end end if z.b<=0 then del(zn,z) end end if not inz then pacc=0 end updpick(dt) if state~="play" then return end for e in all(foes) do if e.hp>0 and dp(e)<min(e.r,10)+6 then hurt(e.dmg) end end if B and dp(B)<22 then hurt(15) end if form==5 and fedt>5 and hp>maxhp*.3 then hp=max(maxhp*.3,hp-.5*dt) end if regen>0 then heal(regen*dt) end if hp<=0 then entertally("death") return end if pendingrival then pendingrival=false setmodal("the rival soul",{"the brute falls.","his soul hovers, waiting.","mercy: +12 karma.","execute: -12 karma,","and steal an upgrade."},{"mercy","execute"},"rival",1) return end if pendingfinal then pendingfinal=false setmodal("the empty throne",{"the judge is defeated.","the throne sits empty,","the wheel is still.","sit: free play with gods.","step off: the true ending."},{"sit on the throne","step off the wheel"},"final",1) return end if lvlq>0 then lvlq-=1 openchoices(3,"level") end end
-- drawing

function drawworld() camx=cl(px-64,0,640) camy=cl(py-64,0,640) camera(camx,camy) cls(3) for gy=flr(camy/8),flr((camy+120)/8)+1 do for gx=flr(camx/8),flr((camx+120)/8)+1 do local n=gy*96+gx local v=band(shr(peek(8192+n\4),(n%4)*2),3) if v==1 then pset(gx*8+3,gy*8+4,(gx+gy)%3==0 and 4 or 11) elseif v>1 then spr(158+v,gx*8,gy*8) end end end rectfill(0,600,767,607,4) rect(1,1,766,766,5) for P in all(PL) do drw(141,P.x,P.y,16,16,0) circ(P.x,P.y,P.done and 26 or 26-P.ch*13,P.done and 1 or 11) if not P.done and dp(P)<44 then print("z: pray  x: smash",P.x-34,P.y-18,7) end end for z in all(zn) do if z.k==1 then if z.wn>0 then circ(z.x,z.y,z.r,8) else drw(128,z.x,z.y,16,16,0) end elseif z.wn>0 then line(z.x,0,z.x,767,10) else rectfill(z.x-z.w,0,z.x+z.w,767,10) end end for p in all(pk) do if p.k=="chest" then drw(109,p.x,p.y,16,16,0) else if p.k=="mark" and markearned==129 then pal(10,8) spr(176,p.x-4,p.y-4) pal() else spr(PKS[p.k],p.x-4,p.y-4) end end end for a in all(ac) do drw(fr%32<16 and 100 or 134,a.x,a.y,16,16,0,cos(a.a)<0) circfill(a.x,a.y-11,2,10) if dp(a)<16 then print("x: slay",a.x-10,a.y-19,8) end end for e in all(foes) do local k=e.k local an,md=fr%32<16 and FFA[k] or FSN[k],FSF[k] if e.mf then pal(7,13) pal(15,2) pal(10,9) pal(11,3) pal(12,1) an,md=fr%32<16 and FDA[e.mf] or FDS[2*e.mf],FDS[2*e.mf-1] end drw(an,e.x,e.y,e.w,e.h,md,cos(e.face)<0) pal() end if B then local x,y=B.x,B.y local g=B.god local bn=B.b1 if g==7 then bn=fr%8<4 and B.b2 or bn elseif g==2 then bn=B.vac>0 and B.b2 or bn elseif g==3 then bn=(B.tele>0 or B.dash>0) and B.b2 or bn elseif g==4 or g==6 then bn=fr%16<8 and B.b2 or bn else bn=fr%48<24 and B.b2 or bn end drw(bn,x,y,32,32,2) pal() if g==2 and B.vac>0 then sspr(112,32,16,16,x-16,y-6,16,16) sspr(112,32,16,16,x,y-6,16,16,true) end if B.tele>0 then circ(x,y+13,3+B.tele*9,8) end if B.tr[1]>0 then for i=0,B.tr[1]-1 do local sa=B.tm*.4+i/B.tr[1] circfill(x+cos(sa)*B.tr[2],y+sin(sa)*B.tr[2],1,7) end end end if not (pinv>0 and fr%4<2) then drawform(form,px,py,face,avt,mvflag,true) end if avt>0 then local fx,fy=cos(face),sin(face) spr(177,px+fx*16-4,py+fy*16-4,1,1,fx<0,fy<0) end for p in all(pp) do line(p.x-p.dx*2,p.y-p.dy*2,p.x,p.y,10) pset(p.x,p.y,7) end for p in all(ep) do if p.k=="bone" then spr(166,p.x-4,p.y-4) elseif p.k=="slash" then line(p.x-p.dx*5,p.y-p.dy*5,p.x+p.dx*3,p.y+p.dy*3,7) line(p.x-p.dx*5-p.dy,p.y-p.dy*5+p.dx,p.x+p.dx*3-p.dy,p.y+p.dy*3+p.dx,10) else circfill(p.x,p.y,2,p.k=="ember" and 9 or 7) end end camera() end
function bar(y,h,f,c) rectfill(2,y,50,y+h,1) rectfill(2,y,2+48*f,y+h,c) end
function drawhud() rectfill(0,0,127,15,0) bar(2,3,max(0,hp/maxhp),8) bar(7,2,min(1,xp/need),12) print("l"..lvl,53,2,7) print((karma>0 and "+" or "")..flr(karma),104,2,karma>0 and 11 or (karma<0 and 8 or 7)) for q=34,94,20 do pset(q,13,q<64 and 8 or 7) end line(64+karma\2,12,64+karma\2,14,10) if state=="play" then rectfill(0,16,127,17,1) rectfill(0,16,127*min(1,tsec/60),17,12) for q=1,3 do pset(q*31.75,16,7) end end if B then rectfill(14,120,114,124,1) rectfill(14,120,14+100*max(0,B.hp/B.mh),124,8) end if bant>0 then local w=#bantxt*4+6 rectfill(64-w/2,20,64+w/2,29,0) print(bantxt,64-#bantxt*2,22,10) end end
function drawchoice() box(9,30,119,100) print(chsrc=="level" and "level up: choose" or "choose an upgrade",16,34,7) for i=1,#ch do local y=48+(i-1)*14 spr(UI[ch[i]],14,y-2) print((i==sel and "> " or "  ")..UN[ch[i]].." x"..U[ch[i]],26,y,7) end end
function drawmodal() box(9,36,119,96) print(modal.t,16,40,10) for i=1,#modal.l do print(modal.l[i],16,48+(i-1)*6,7) end for i=1,#modal.o do print((i==modal.sel and "> " or "  ")..modal.o[i],16,80+(i-1)*7,7) end end
function drawtally() box(9,14,119,116) local ts=flr(tsec) print((won and "god felled  " or "you died  ")..flr(ts/60)..":"..(ts%60<10 and "0" or "")..ts%60 .."  level "..lvl,16,20,won and 10 or 8) print("kills "..kills.."  karma "..flr(karma),16,27,7) if markearned>0 then if markearned==129 then pal(10,8) end spr(176,16,36) print(marktxt,26,38,7) elseif marktxt~="" then print(marktxt,16,36,7) end if crownnote~="" then print(crownnote,16,46,10) end local pf=pform(flr(karma)) print("next: "..(pf>0 and FN[pf] or FN[ladder(flr(karma))]),16,55,7) if carry>0 then print("kept: "..carry.." upgrades",16,66,11) end print("z: be reborn",16,106,5) end

function drawrebirth() cls(0) local pf=pform(lastk) local nf=pf>0 and pf or lives==0 and 1 or ladder(flr(lastk)) if dfm>0 then nf=dfm end drw(FH[nf],64,38,32,32,FDS[2*nf-1]) local nm=FN[nf] print(nm,64-#nm*2,58,7) print("bosses defeated",34,67,5) for r=0,1 do if r==1 then pal(10,8) end for i=1,6 do if (r==0 and sun or blood)[i]==1 then spr(176,22+i*9,76+r*12) end end end pal() if crown(sun) then spr(168,8,76) end if crown(blood) then spr(167,104,88) end print("f:"..(dfm==0 and "-" or FN[dfm]).." b:"..(dbs==0 and "-" or GN[dbs]),8,102,5) print(crown(sun) and crown(blood) and "z: normal life   x: ascension" or "z: begin life",14,122,10) end
function drawending() cls(0) print("you step off the wheel",22,40,10) print("no more marks. no more hunger.",14,56,7) print("the gods keep their thrones.",20,66,7) print("you keep the silence after.",22,76,7) print("z: return",48,100,5) end
-- entry
function _init() wph=0 dfm,dbs=0,0 loadsave() state="rebirth" music(0) end
SU={level=updchoice,modal=updmodal,tally=updtally}
function _update60() fr+=1 if state=="rebirth" then dfm=(dfm+(btnp(1) and 1 or 0)-(btnp(0) and 1 or 0))%8 dbs=(dbs+(btnp(2) and 1 or 0))%8 if btnp(5) and crown(sun) and crown(blood) then startlife(true) elseif btnp(4) then startlife(false) end elseif state=="ending" then if btnp(4) then state="rebirth" end else local f=SU[state] if f then f() else updateplay(1/60) end end end
function _draw() pal() if state=="rebirth" then drawrebirth() return end if state=="ending" then drawending() return end drawworld() drawhud() if state=="level" then drawchoice() end if state=="modal" then drawmodal() end if state=="tally" then if diss<1 then for i=1,diss*520 do pset(rnd(128),rnd(128),0) end else drawtally() end end end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000070000000000000000000000000000d000000000000000000000000000000000000000000000000
000000000000050000000000000000000000000000000004007700000000001500000000000000d6000000000000000000000000000001000000000000001001
00000000000010000000000000000000000000004000094901677000000001990000000000000d6700010000000000000000000000111a1a000000000111661a
0000000000051000000000000000000000000000999494990106770000001997000000000000d677001010000000000100000000116614a40000000000666194
000009000000510000000000000005550000000024999949010067700001997700000000000d7777001001000000001f00000001115d144900000001111dd1a4
000099000000511100000000000555550000000002499999007706770001799900000000000d7777001f00100000001f00000001a4555a410000000aa9155114
00009a9000011514000000000059aaa90000000044944999006770677001a95900000000000d7777000ff001000001f7000001a9441511110005000004411d11
0000aa0000111144000000000a155995000000099922449401067700770191ee0000000003cd7777001fff00100001f7000001a44415d111000005000a11d611
000aaa90002112a40000000000a055550000000292f912490100666667011e1f000000003cc367770010f77001001f77000101446111d6100000000041111661
000aaa81844212880000000050005551000000494f4919290010007767111eff00000003cccc3677001f0ff70f1017f700016114111111110000000511111111
0009a1184448218a000000005f5555550000000942919f9400017776661111ff00000013ccccc3330007700fff101d170001d6d1111d61aa05000000011d61aa
000aa81444882418000000011d6fff6f000000249219fff9000011066671111f0000003ccccccccc000df700ff101d1a001dddd161151aa40000000006151a88
00aa11822288e421000000555155dddd0000002942144ff90005066760717111000003cccccccccc00010fff4ff11199000d111dd6117911001a44411d117788
008a81484228a884000000955111111100000f49921144f900001176601996650000033ccccccccc0000747f4dff11f4000194111d1aa17700019441111a8881
00aa122221128884000005555155555500000f449214421900001000619799770000333333cccccc0000f7f004dfdfff001944a1111a4171000a4411101a8811
00a128221118224400009910dfffffff00000941921ff29f000005000799767900001cc3333ccccc000001df0ddff77f00047511101a4161001a4441111a8811
000148211112248a00005550d6ffffff00000941921fff9f0000001107197797000013317133cccc0000001ffd1df777000147a1111aa1d700014a11161a8881
0001488811114444000555506666ffff000009444421f9140000000517117797000013c117133ccc00000001fd11f7770014a7a116119911000611166d119888
0000480e11111118000550006ff666660000099914211f9100000000766167990000113c11713ccc00000000f101fff70001116ddd161944001dd6d1d1161988
00012408111815550059550056ffffff0000ff9914221114000000006061169900000d3cc1113ccc000000000001dfff0001d6ddd11dd1990001ddd1111dd1a1
0000020111882111005555005566ffff0000f9f9121212ff000000010091619900000d73cc3333cc0000000000014dff0001ddd1111111110001d11a111111a1
0000010018a8215200555505155666660000f9f941212299000000010991165900000d67133313cc0000000000014ddd00001146a111155100010194a1116d10
0000000018a200000055100a515555550000fff991112044000000019910116100000076d773113300000000001fd11400001146da116511000001975a16d111
0000000018820015001150099515555500000fff9122000400000019910016690000311d7677c27200000000047744110000011497a11611000001447716d11a
0000000111211001000550055510000000009fff912000000000001910001569000cc310066dd222000000001f7f1191000000044916611a000000014a6ddaaa
0000004241200000000000fd50000000000ffffff900000000000011000005690001333000d67d27000000110ffd014100000001111dd14700000001116d166d
00000171720000000000000000000000000f9f2f9900000000000000000000190000310000000ddd000001000dd100100000000000ddd1970000000011dd1449
00000111111000000000000000000000000290f2900000000000000000000016000000000000000000000011f1100000000000000111dd1400000000001114aa
000000000000000000000000000000000000000000000000000000000000001d0000000000000000000000fff000000000000000000010010000000000000100
00000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000010000000000004a0000000000003aaa024f4244000000dd00000004000000000000000000000111
00000000000077000000000000000000000000000000010001100011000004a9000f00020000aaaa02ff424400000d7700000049000000000000000111544449
000011000007d7aa00000004000f000200000000000011000110001a000004410004f4440003aaab024ff4440000d7770000049a000066660000015555544455
00000190006655aa0000009f0004f44400000006000010000110001100000144000024f40003a7bb002224440000d777000004410006666600001155152d5462
001111110006551d000000ff000024f4000000670001000801110119000001410002211f0003b1bb0000024f0000d77700000144000666660000151256e615d2
01001111066655170000009f0002211f000000610011110800191ff400004111000221140000bbbb0000024f0000d71700000141006666660001152dd5612121
00001111006d56550000055400022114000000670111008201f1f4ff0004aa4400022119003abbbb0000052f000000000000411100555555011552dd12211111
0000111106ddd19a000005950002211900067777011102280111414900041a1a0044222403abbbbb000024440000711d000499440056116601551dd121111111
000011aa0666d11a000009950004222400066777010102220011111f00aa14a9004442ff3b3baab3000044ff000077d7000419190056666615522d1211111111
001141990666591400000994000442ff000006771101024100101121001114aa002244ff033aab33000024ff0000dd770099149a005665661551251111122221
011111490666d11100000595004244ff000006771101011100001f420044914100224fff03333330000022ff000007d70011149900566566114427d212244444
00101199006d69110000059900424fff0000066651010004000019120a9711910000244f000000000000022400007dd70044a141005666160154426d22242222
0000111100006655000055990020244f00000606011000080000141104a994410000424400000000000044200000717d09af11a10056666600154526f4e15521
0001101400006055000055990000424400000000000011010001141000aa4a490009444000000000000000000000ddad049aa44100556111000154451565d6d2
0011000100000005000055450009444000000000000000080001110000000000000000000000000000000000000000dd0099494a000666660000011551144552
00000000000000250000555d00000000000000000000000000000000000000000000000000000000000000000000007700000000000666660000000000015515
00000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000007000000000000
00000000001000000000000000000000000000000000000000000000000000000004400000000000011000110000000000000000000000000066770000000000
000000000011000000000000000011110000049900000000000000000000000000421400000000000110001a0000000000000000000000000006d7aa00000000
000001000017100100000000000117dd000054a9000000000000000000000000024f42440000000001100011000000000000000000000000066655aa00000000
000001000014711a000000000011e77d0000559100000000000000000000000002ff42440000000001100119000000000000000000fffffa006d551d00000000
0000011100174f17000000000011e7dd00005111000000000000000000000000024ff4440000000001101ff40000000000000000004444aa06dd551700000000
00010177001fffa700000000011eeddd0000111100000000000000000000000000222444000000000111f4ff0000000000000000004444a00666565500000000
001117770001f4a700000000011eeddd00009ff90000000000000000000000000000024f00000000001941490000000000000000004444a00666d19a00000000
00017777001141a700000000011e21dd000004ff0000000000000000000000000000052f0000000001f1111f00000000000000000044444a0666d11a00000000
00017777000011a700000000011222d200000f5400000000000000000000000000002444000000000111112100000000000000000044444a006d591400000000
000177170000014a00000000001121220000ff55000000000000000000000000000044ff0000000000111f4200000000000000000044404a0006d11100000000
00001717000000140000000000011e220000f959000000000000000000000000000024ff000000000010191200000000000000000044444a0000691100000000
0000017700000001000000000eeeee2200009955000000000000000000000000000022ff000000000000141100000000000000000044444a0000665500000000
00000011000000010000000000eeeeee0000059500000000000000000000000000000224000000000001141000000000000000000044404a0000605500000000
000000000000000000000000000000000000044000000000000000000000000000004420000000000001110000000000000000000044444a0000000500000000
00000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000002500000000
000000080000000000000000000000000000000000000000000000000000000000000000000000dd000000000000000000000000000000000000000000000000
09000008000000000100000000006666000001000000000400000499000011000000000000000d77000000000000000000000000000000040000000000000000
00000089000000000110000000066666000111000000009f000054a900000190000000000000d777000003330000000000000111000000440000000000000000
0800008900000066017100110006666600111000000000ff0000559100011111000000000000d77700003aaa00000000000017ee000004940000000000001001
0800089900000677014711a700666666011100080000009f0000511100001111000000000000d7770000aaaa000000000001d77e000044410000000000001001
08800899000006170174f1770055555501111108000005540000111100011111000000000000d7170003aaab000000000001d7ee00244412000000000000111c
888089990000067701fffa7700561166010100820000059500009ff900101111000000000000711d0003a7bb00000000001ddeee004442240000000000101ccc
8888999900067777001f4a77005666661101022800000995000004ff000111aa00000000000077d70003b1bb00000000001ddeee004142940000000000111ccc
8889999a00066777001141a700566566110102220000099400000f5400114199000000000000dd770000bbbb00000000001d21ee00042994000000000001cc77
889999aa00000677000011a70056656651010241000005950000ff550111114900000000000000dd003abbbb00000000001222e2000427d4000000000001cc77
899999aa000006770000014a0056661601010111000005990000f9590010119900000000000007d703abbbbb0000000000012122000427d8000000000001c717
99999aaa000006660000001400566666010000040000059900009955000011110000000000007dd73b3baab30000000000001d2200428ad90000000000001c17
9999aaaa00000606000000010055611101100008000005990000059500141014000000000000717d003aab330000000000dddd220099999900000000000001cc
099aaaa700000000000000010006666600001101000005450000044101110001000000000000ddad0033333000000000000ddddd000442000000000000000011
09aaaa77000000000000000000066666000000080000055d000004150000000000000000000000dd000000000000000000000000000440000000000000000000
00aaaa77000000000000000000055555000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000007700000080088008a00aa00a000cc000000000000000000000000000000000000000000000000000
0000000000e0a000000000000000000000000000000000007770000022822822aaaaaaaa00cccc00000000000000000000000000000000000000000000000000
00b00b000b0b0b00000000000000000000000000000000000777000022222222aaaaaaaa0c7cccc0000000000000000000000000000000000000000000000000
00b03b0000b7b000000000000000000000000000000000000077000022288222aaaccaaaccccccc0000000000000000000000000000000000000000000000000
0b3b03b00b0b0b00000000000000000000000000000000000007700022222222aaaaaaaa0ccccc00000000000000000000000000000000000000000000000000
0b3b03b0000000000000000000000000000000000000000000007770000000000000000000ccc000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000007770000000000000000000c0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000
000990000a70000000070000000000000000000000000000000aaa00088088007777777700000000444444400770077000000000000000000000000000000000
09000090007a00000007000000000000000000b00000000000a770008888888055555555000ee000044444000880088000000000000000000000000000000000
000aa0000007000000076000000000000000b00b0000000000aaaaaa8e88888056555565000ee000004a40000880088000000000000000000000000000000000
90a7aa090007a0000007600000000000700b00b0000000000aaaaaa088888880555555550eeeeee0000a00000880088000000000000000000000000000000000
90aaaa090007a00000aaa0000000000070b07000000000000aaaaa0008888800055555500eeeeee0004a40000880088000000000000000000000000000000000
000aa000007700000004000000000000700b00b000000000aaaa00000088800005555550000ee00004a4a4000088880000000000000000000000000000000000
09000090077a000000040000000000000000b00b0000000000a000000008000000555500000ee000444444400008800000000000000000000000000000000000
000990000a0000000009000000000000000000b0000000000a000000000000000005500000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000010000000000000000000000000000d000000000000000000000000000000000000000000000000
000000000000050000000000000000000000000000000099001000000000001500000000000000d6000000000000000000000000000000110000000000000011
00000000000010000000000000000555000000000000009901710000000001990000000000000d67000100000000000000000000000111660000000500011166
0000000000051000000000000005555500000000009999990177100000001997000000000000d677001f10000000000100000000011aa91d00000000000aa91d
0000000000005100000000000055aaa50000000009999999016771000001997700000000000d7777001ff1000000001f000000011aa44a150000000050004a15
0000000000005111000000000059aaa90000000090099999001677100001799900000000000d7777001fff100000001f000000161449a411000500000000a411
0000090000011514000000000a1559950000000000409944001167710001a95900000000000d77770001f771000001f70000016dd1a4111d0000000005a4111d
00009900001111440000000000a05555000000044040999401771677100191ee0000000003cd7777001f4ff7100001f700000115551111160000000000111116
00009a90002112a4000000005000555100000044400099f40167716775011e1f000000003cc36777001774dff1001f7700001a415151111600001a4000011116
0000aa8184421288000000005f5555550000000444099fff0016771177111eff00000003cccc36770014f744ff1017f70000194415d611110000194410061111
000aa1184448218a000000011d6fff6f00000049414999f900016666671111ff00000013ccccc33300014fffdf101d170001a44411dd61aa0001a44411dd61aa
000aa81444882418000000555155dddd0000049991911999000011776771111f0000003ccccccccc000d747fdf101d1a0001a46111151aa40001a46111151a88
000911822288e4210000009551111111000004994194714f0005777666717111000003cccccccccc0001f7f44ff1119900014a411111791100014a4111117788
008a81484228a8840000055551555555000000994199999f00001116661996650000033ccccccccc000014df4dff11f400161111111aa17700161111111a8881
00aa122221128884000005151d66666600000999419999ff00001667619799770000333333cccccc00001d1ff4dfdfff001d6d16661a4171001d6d16661a8811
00a128221118224400009910dfffffff0000999999199f19000005766199767900001cc3333ccccc000001d4fddff77f001ddd1ddd1a4161001ddd1ddd1a8811
000148211112248a00005550d6ffffff000099949914fff20000001161197797000013317133cccc00000011fd1df777001d1111111aa1d7001d1111111a8881
0001488811114444000555506666ffff000044999911ffff0000000517117797000013c117133ccc00000001dd11f777000194a111119911000194a111119888
0000480e11111118000550006ff66666000004999941444100000000176167990000113c11713ccc000000001101fff7000194a111161944000194a111161988
00012408111815550059550056ffffff000009999949114f000000005761169900000d3cc1113ccc000000000001dfff0001475a116dd1990001475a116dd1a1
0000020111882111005555005566ffff00000999949941ff000000017691619900000d73cc3333cc0000000000014dff0000147a16dd11110000147a16dd11a1
0000010018a8215200555505155666660000099949999114000000016991165900000d67133313cc0000000000014ddd000014a16dd11115000014a16dd11a15
0000000018a200000055100a515555550000009449994411000000019910116100000076d773113300000000001fd11400000116dd11111500000116dd11a115
00000000188200150011500995155555000000404999499900000019910016690000311d7677c1110000000004774411000001ddd1aa1116000001ddd1aaa116
0000000111211001000550055510000000000040094449990000001910001569000cc310066dd777000000001f7f11910000001d146daa110000001d146daa11
00000042412000000000005111100000000000000044949900000011000005690001333000d67ddd00000011fffd014100000001144974160000000114497a16
0000017172000000000000fd50000000000000000000499900000000000000190000310000000ddd000001fffdd10010000000000114491d0000000001aa191d
00000111111000000000000000000000000000000000009900000000000000160000000000000000000000111110000000000000000111dd00000000000111dd
000000000000000000000000000000000000000000000009000000000000001d0000000000000000000000000000000000000000000000110000000000000011
00000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000
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
000800003245000000000000000035450000000000000000394500000000000000003e4500000000000000003c4500000000000000003e440000000000000000394400000000000000003e450000000000000000
000800001a05000000000000000000000000000000000000210400000000000000000000000000000000000026050000000000000000000000000000000000002604000000000000000000000000000000000000
00080000355200000000000000000000000000000000000039520000000000000000000000000000000000003e520000000000000000000000000000000000003e52000000000000000000000000000000000000
000a00002d05000000000000000000000000002905000000000000000000000000002605000000000000000000000000002404000000000000000000000000002605000000000000000000000000000000000000
000a00001a05000000000000000000000000000000000000000000000000000000001d04000000000000000000000000000000000000000000000000000000001a05000000000000000000000000000000000000
000a00003252000000000000000000000000000000000000000000000000000000002e52000000000000000000000000000000000000000000000000000000002d52000000000000000000000000000000000000
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
04 10111220
04 13141520
