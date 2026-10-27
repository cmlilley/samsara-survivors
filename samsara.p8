pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- samsara survivors: data-driven rewrite (entity modes, boss sequencer, event places)
fr=0
GN={"narak","vora","ferrox","aurel","kharun","lumara","the judge"}
FN={"soul mote","deva","virtuous human","animal","hungry ghost","hellborn","asura","buddha"}
FHP=split("60,140,120,105,90,75,150,150")
FSPD=split(".95,1.2,1.15,1.1,1.05,1,1.25,1.25")
FDMG=split(".9,1.25,1.15,1.1,1.05,1,1.35,1.35")
FH=split("64,47,97,66,98,68,77,220") FCAP=split("3,8,6,5,4,4,8,8")
EN={"slime","rat","skeleton","soldier","guardian","wisp","ghost","big slime","brute","turret"}
-- foe rows: hp,spd,dmg,ess, mode, a,b,c,d,e,pspd
-- modes: 1 pulse, 2 weave, 4 shooter, 5 melee, 6 phase
-- shooter a=proj b=cd c=pdmg d=band-in e=band-out; melee a=jab-dmg b=jab-cd
ETS={"6,.35,4,1,1,0,0,0,0,0,0,.8,.4375,0,0,0,8","4,.8,3,1,2,0,0,0,0,0,0,0,0,0,0,0,8","8,.4,4,3,0,bone,1.6,5,62,48,1.7,0,0,0,0,0,8","40,.3,12,12,0,poke,1.3,7,0,0,1.8,0,0,0,18,0,8","26,0,6,6,0,bolt,1.9,6,0,0,1.1,0,0,0,0,0,8","5,.5,6,3,1,ember,1.7,5,0,0,1.4,2.4,.5,.3,0,0,8","7,.55,0,2,1,bolt,2,4,0,0,1.2,.8,.4375,0,0,0,8","24,.3,6,9,1,0,0,0,0,0,0,.8,.4375,0,0,24,12","220,.28,18,45,0,bolt,1,10,0,0,1.5,0,0,0,24,0,16","20,0,0,6,0,bolt,1.5,5,0,0,1.8,0,0,0,0,0,8"}
ET={} for i=1,10 do ET[i]=split(ETS[i]) end
FSN=split("99,72,100,101,102,103,104,99,101,106")
FSF=split("0,1,0,0,0,0,0,0,0,0")
FDS=split("0,64,0,47,0,97,1,66,0,98,0,68,0,77,1,220")
PT=split("6,7,5,4")
PKS={ess=132,mark=128}
function ucap(i) return min(UM[i],asc and 8 or FCAP[form]) end function mkcarry() carry=0 for i=1,10 do if saved[i]>0 then carry+=1 end end end LAY=split("145,146,-145,147,148,150,148,149,147") ANC=split("96,544,552,424")
-- boss patterns per god, split rows: mv,mind,cd, akind, params...
-- akind: 1 pend(p1: 2 dash/3 swipe, p2 delay, p3 dash-spd)
-- 3 fan(n,step,sp,dm) 4 zones(p1: 1 patches/2 beams)
-- 5 set(p1: 1 vac/2 kwaves)
BPS={".6,36,2.6,4,1",".22,46,3.5,5,1",".5,0,2.6,1,2,.6,4",".45,42,1,3,3,.1,2,7","0,0,2.4,5,2",".3,42,3.2,4,2",".45,30,0,0"}
BP={} for i=1,7 do BP[i]=split(BPS[i]) end BTS={"0,0,0,0,0,0,0,0,0,0,0,0,0,0","0,0,0,0,0,3,2,0,0,0,0,0,0,0","0,0,0,0,0,0,0,0,0,0,0,0,0,0","0,0,0,8,5,0,0,0,0,0,0,10,0,1","3,20,8,0,0,0,0,0,.25,0,0,0,0","0,0,0,0,0,0,0,0,0,0,0,0,0,0","0,0,0,0,0,0,0,50,3,0,0,0,0,0"} DBK=split("0,70,35,0,-35,-70,0")
BSP=split("0,0,160,4,156,4,11,4,2,0,4,0,164,4")
JACT={bolt=split("0,0,1.4,3,5,.06,2,7"),melee=split("0,0,1.8,1,3,.5")}
UN={"melee","bolt","spread","damage","speed","max hp","armor","regen","cooldown","magnet"}
UI=split("134,135,136,137,138,139,140,141,143,144")
UM=split("5,5,4,5,5,5,5,5,5,5")
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



function recalc() local bh=asc and 150 or FHP[form] local bd=asc and 1.35 or FDMG[form] maxhp=bh+bmax+18*U[6] hp=min(hp,maxhp) dmgs=bd*(1+.12*U[4])*(form==6 and 1.05 or 1) spd=1.4*FSPD[form]*(1+.09*U[5]) pdmg=10*dmgs*(1+.22*U[1]) bdmg=7*dmgs*(1+.22*U[2]) rng=20+3*U[1] mag=(16+10*U[10])*(form==5 and 2 or 1) essm=form==5 and 1.2 or 1 armor=U[7] regen=(form==2 and .5 or form==8 and 1 or 0)+.6*U[8] end
function unlock(w) if w==8 then bank2=1 dset(33,1) else bank=1 dset(31,1) end end function pform(k) return bank+bank2==0 and 0 or bank==0 and 8 or bank2==0 and 7 or k>=0 and 8 or 7 end function ladder(k) return k>=60 and 2 or k>=20 and 3 or k>=-19 and 4 or k>=-59 and 5 or 6 end
function kadd(v) karma=cl(karma+v,-100,100) end
function heal(v) hp=min(maxhp,hp+v) end
function gainxp(v) v*=essm ess+=flr(v) xp+=v while xp>=need do xp-=need lvl+=1 lvlq+=1 need=5+4*lvl+lvl*lvl end end
-- life setup
function startlife(a) asc=a foes,pp,ep,pk,zn,ac,B={},{},{},{},{},{},nil U={} for i=1,10 do U[i]=0 end lvl,xp,need,ess,kills,bmax=1,0,10,0,0,0,0 karma=lastk hp,px,py,face,pinv,pcd,bcd,avt,tsec,tmin,df,lvlq=1,384,384,.25,0,0,0,0,0,0,0,0 local pf=pform(karma) form=pf>0 and pf or asc and ladder(flr(karma)) or lives==0 and 1 or ladder(flr(lastk)) for i=1,10 do U[i]=min(saved[i],ucap(i)) end if dfm>0 then form=dfm karma=DBK[dfm] end lives+=1 dset(35,lives) recalc() hp=maxhp spawnt,markearned=1,0 won=false marktxt,crownnote="","" nextinn,fedt,pacc,ascidx,ascnext=6,0,0,1,20 lastr=0 cht=25 for P in all(PL) do P.done=false P.ch=0 P.on=false end state="play" ban(asc and "ascension life" or FN[form]) music(asc and 3 or 1) if dbs>0 then dolock() spawnboss(dbs,lockform) end end
-- drawing helpers
function drw(n,x,y,w,h,m,f) if m==4 then spr(n,x-16,y-16,4,4) return end local sx,sy=(n%16)*8,flr(n/16)*8 if m==0 then sspr(sx,sy,8,16,x-w/2,y-h/2,w/2,h) sspr(sx,sy,8,16,x,y-h/2,w/2,h,true) elseif m==1 then sspr(sx,sy,16,16,x-w/2,y-h/2,w,h,f) end end
function drawform(f,x,y,fa,at,m,pv) local fx,fy=cos(fa),sin(fa) local ff=fx<0 local n=FDS[2*f] if m then y+=((f==2 or f==6) and sin(fr*.07)*2.5 or sin(wph)*1.1) end local wf=at>0 or fr%24<12 if f==1 then n=fr%12<6 and 64 or 65 elseif f==2 or f==6 then local wn=wf and 76 or 75 if f==6 then pal(7,10) pal(14,9) end for i=0,1 do spr(wn,x-12+i*16,y-6,1,2,i>0) end pal() if f==2 and at>0 then n=74 end elseif f==7 then n=at>.1 and 79 or at>0 and 96 or 77 elseif f==8 then circ(x,y-3,8+fr%16,10) for i=0,11 do local a=fr*.01+i/12 local r=i%2==0 and 19 or 15 line(x+cos(a)*9,y-3+sin(a)*9,x+cos(a)*r,y-3+sin(a)*r,i%2==0 and 10 or 9) end end if f==4 and m and fr%16>=8 then n=224 end drw(n,x,y,16,16,FDS[2*f-1],ff) if f==4 and m and sin(wph)<0 then local c=ff and 126 or 125 spr(c,x-8,y,1,1,ff) spr(251-c,x,y,1,1,ff) end if f==3 then line(x+fx*3,y+fy*3,x+fx*10,y+fy*10,4) circfill(x+fx*10,y+fy*10,1,10) line(x-1,y,x+2,y+3,8) end if f==2 or f==6 then for i=0,2 do local a=fr*.04+i/3 pset(x+cos(a)*12,y+sin(a)*5,f==2 and 10 or i%2==0 and 9 or 8) end end if pv and form==2 then circ(x,y-13,4,10) end end


function addpick(k,x,y,v) add(pk,{k=k,x=cl(x,10,758),y=cl(y,10,758),v=v or 1}) end
function spawnpos() local a=rnd() local r=95+rnd(55) return cl(px+cos(a)*r,10,758),cl(py+sin(a)*r,10,758) end
function spawnfoe(t,x,y) if not x then x,y=spawnpos() end local b=ET[t] local e={k=t,x=x,y=y,face=.25,kx=0,ky=0,burn=0,tm=rnd(),acd=.5+rnd(1.5),hp=b[1]*(1+.2*tmin),dmg=b[3],ess=flr(b[4]*(1+.25*tmin)),scale=b[16],r=b[17],w=b[16]>0 and b[16] or 16,h=16} add(foes,e) return e end
function rpick(t) return t[flr(rnd(#t))+1] end
function pickn(p,c) local o={} for i=1,c do local j=flr(rnd(#p))+1 add(o,p[j]) p[j]=p[#p] p[#p]=nil end return o end
function picktype() local m=tmin if m==0 then return rnd()<.12 and 3 or flr(rnd(2))+1 end local o={1,1,2,2,3} for i=1,min(4,m) do add(o,PT[i]) end if m>=3 and rnd()<.1 then return 8 end return rpick(o) end
function addep(x,y,a,sp,d,k) add(ep,{x=x,y=y,dx=cos(a)*sp,dy=sin(a)*sp,d=d,k=k,t=0,life=2.5/sp}) end
function hurt(d,u) if u then if hp>0 then hp-=d end return end if pinv>0 or hp<=0 then return end sfx(42) hp-=max(1,d-armor) pinv=.5 end
function dmgx(t,d,kx,ky,src) if t.hp<=0 then return end if t.god==4 and t.shield then d*=.25 end t.hp-=d if t.k then t.kx+=kx t.ky+=ky end if form==6 and (t.god or src==1) then t.burn=3 end if t.god and t.hp<=0 then killboss() end end
function killfoe(e) kills+=1 addpick("ess",e.x+rnd(9)-4,e.y+rnd(9)-4,e.ess) if e.k==8 then for i=1,2 do spawnfoe(2,e.x+rnd(13)-6,e.y+rnd(13)-6) end end if e.k==9 then pendingrival=true addpick("chest",e.x,e.y) end end
function sweepfoes() for e in all(foes) do if e.hp<=0 then killfoe(e) del(foes,e) end end end
function killboss() sfx(43) addpick(asc and "chest" or "mark",B.x,B.y) if B.judge then pendingfinal=true B=nil return end if asc then ascidx=B.god+1 B=nil local nf=karma>=100 and 8 or karma<=-100 and 7 or form<7 and ladder(flr(karma)) or form if nf~=form then form=nf recalc() ban("you become: "..FN[form]) end if abs(karma)>=100 then unlock(karma>0 and 8 or 7) end return end markearned=0 if B.form=="feral" then marktxt="no mark: feral god" else local tr=B.form=="trial" local tb=tr and sun or blood local was=crown(tb) tb[B.god]=1 dset((tr and 0 or 6)+B.god,1) markearned=tr and 128 or 129 marktxt=(tr and "sun mark: " or "blood mark: ")..GN[B.god] if not was and crown(tb) then crownnote=tr and "crown of heaven earned" or "crown of hell earned" unlock(tr and 8 or 7) end end B=nil won=true end
-- combat
function nearT(x,y,r,ph) local bt,bd=nearfoe(x,y,r,nil,nil,ph) local bk=bt and "f" or nil if B then local d=dst(x,y,B.x,B.y) if d<bd then bk,bt,bd="b",B,d end end return bk,bt,bd end
function arhit(r,d,src) local kb=src==1 and 1.5 or 0 for e in all(foes) do if e.hp>0 and dp(e)-e.r<=r then local a=af(e) if adf(a,face)<=1/6 then dmgx(e,d,cos(a)*kb,sin(a)*kb,src) end end end if B and dp(B)-16<=r and adf(af(B),face)<=1/6 then dmgx(B,d,0,0,0) end end
function doswing(tg) face=af(tg) avt=.16 arhit(rng+3,pdmg,1) end
function firebolt(tg) local a=af(tg) local n=1+U[3] for i=1,n do local aa=a+(i-(n+1)/2)*.035 add(pp,{x=px,y=py,dx=cos(aa)*3.2,dy=sin(aa)*3.2,d=bdmg,life=.62}) end end
function attacks(dt) pcd-=dt bcd-=dt avt=max(0,avt-dt) local cdm=max(.4,.9^U[9]) if pcd<=0 then local bk,tg,d=nearT(px,py,9999,true) if tg then local ed=d-(bk=="b" and 16 or tg.r) if ed<=rng then doswing(tg) pcd=.55*cdm end end end if bcd<=0 then local tg,bd=nil,112 for e in all(foes) do if e.hp>0 then local d=dst(px,py,e.x,e.y) if d<bd and d-e.r>rng then tg,bd=e,d end end end if not tg then local _,t2=nearT(px,py,112,true) tg=t2 end if tg then firebolt(tg) bcd=.9*cdm end end end
function updpp(dt) for p in all(pp) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=false if B and dd(p,B)<18 then dmgx(B,p.d,0,0,0) dead=true else local hit=nil for e in all(foes) do if e.hp>0 and dd(p,e)<e.r+2 then hit=e break end end if hit then dmgx(hit,p.d,0,0,1) dead=true end end if dead or p.life<=0 or abs(p.x-384)>392 or abs(p.y-384)>392 then del(pp,p) end end end
function updep(dt) for p in all(ep) do p.x+=p.dx*df p.y+=p.dy*df p.life-=dt local dead=p.life<=0 if dp(p)<5 then hurt(p.d) dead=true end if dead then del(ep,p) end end end
-- enemies: one update, mode-dispatched from the ET row
function movefoe(e,tx,ty,sp) local d=dst(e.x,e.y,tx,ty) if d>1 then local a=ang(tx-e.x,ty-e.y) e.x+=cos(a)*sp*df e.y+=sin(a)*sp*df e.face=a end end
function updfoe(e,dt) e.tm+=dt if e.burn>0 then e.burn-=dt e.hp-=2*dt end e.x=cl(e.x+e.kx*df,8,760) e.y=cl(e.y+e.ky*df,8,760) e.kx*=.8 e.ky*=.8 local r=ET[e.k] local sp=r[2] local d=dp(e) e.acd-=dt local jr=e.r+12 if e.acd<=0 and r[15]>0 and d<=jr then hurt(r[15]) e.acd=r[7] elseif e.acd<=0 and r[8]>0 and d<=96 then local a=ap(e)+rnd(.05)-.025 e.face=a addep(e.x,e.y,a,r[11],r[8],r[6]) e.acd=r[7] end if sp>0 then local pu=1 if r[5]==1 then pu=e.tm%r[12]<r[12]*r[13] and 1 or r[14] end if pu>0 then local tx,ty=px,py if r[5]==2 then local a=ap(e) tx,ty=px+cos(a+.25)*14,py+sin(a+.25)*14 end local go=false if r[15]>0 then go=d>jr-2 elseif r[9]>0 then if d>r[9] then go=true elseif d<r[10] then go=true tx,ty=2*e.x-px,2*e.y-py end else go=d>2 end if go then movefoe(e,tx,ty,sp*pu) end end end end
function spawnboss(g,fm) local x=cl(px+(rnd()<.5 and -80 or 80),30,738) local y=cl(py+(rnd()<.5 and -60 or 60),30,738) B={tm=0,acd=1,tele=0,dash=0,vac=0,ring=3,burn=0,waves=0,god=g,tr=split(BTS[g]),form=fm,b1=BSP[2*g-1],bm=BSP[2*g],x=x,y=y,hp=g==7 and 2000 or fm=="feral" and 1200 or 1600} B.mh=B.hp if g==7 then B.judge=true B.mode=max(U[2],U[3])>=U[1] and "bolt" or "melee" end ban(GN[g].." ("..fm..")") music(3) end
function bossfire(a,sp,d,k) addep(B.x,B.y,a,sp,d,k or "ember") end
function radial(n,sp,dm,off) local ra=off or rnd() for i=0,n-1 do bossfire(ra+i/n,sp,dm) end end
function fan(a,n,st,sp,dm) for i=-(n-1)/2,(n-1)/2 do bossfire(a+i*st,sp,dm) end end


function doact(A,a) local ak=A[4] local p1,p2,p3,p4=A[5],A[6],A[7],A[8] if ak==1 then B.tele=p2 B.pend=p1 B.ptm=p2 if p1==2 then B.dsp=p3 end elseif ak==3 then fan(a,p1,p2,p3,p4) elseif ak==4 then if p1==1 then for i=1,3 do add(zn,{k=1,x=px+(i-2)*22+rnd(13)-6,y=py+rnd(25)-12,r=14,wn=.7,b=4,d=6}) end else for i=-1,1 do add(zn,{k=2,x=cl(px+i*24,8,760),w=8,wn=.8,b=1.5}) end end elseif ak==5 then if p1==1 then B.vac=2 else B.waves=3 B.wcd=0 end end end
function updboss(dt) if not B then return end B.tm+=dt if B.burn>0 then B.burn-=dt B.hp-=2*dt if B.hp<=0 then killboss() return end end B.tele=max(0,B.tele-dt) local d=dp(B) local a=ap(B) local sm=B.p2 and 1.4 or 1 local g=B.god local tr=B.tr local busy=false if tr[1]>0 then for i=0,tr[1]-1 do local sa=B.tm*.4+i/tr[1] if dst(px,py,B.x+cos(sa)*tr[2],B.y+sin(sa)*tr[2])<7 then hurt(tr[3]) end end end if tr[4]>0 then local sh=B.tm%tr[4]<tr[5] B.shield=sh if sh and not B.tur then B.tur=true for i=-1,1,2 do spawnfoe(tr[12],B.x+i*26,B.y+10) end end if not sh then B.tur=false end end if tr[10]>0 and d>60 and B.dash<=0 then movefoe(B,px,py,tr[10]*sm) end if B.waves>0 and B.dash<=0 then B.wcd-=dt if B.wcd<=0 then fan(a,5,.06,2,7) B.waves-=1 B.wcd=.25 end end if B.vac>0 then B.vac-=dt local va=af(B) px+=cos(va)*1.1*df py+=sin(va)*1.1*df busy=true if B.vac<=0 then fan(a,tr[6],.12,2,7) for i=1,tr[7] do spawnfoe(1,B.x+rnd(21)-10,B.y+rnd(21)-10) end end end if tr[8]>0 and not B.p2 and B.hp<B.mh/100*tr[8] then B.p2=true B.b1=168 ban("the wheel breaks") end if B.p2 then B.ring-=dt if B.ring<=0 then radial(12,1.5,7,0) B.ring=tr[9] end end local P=BP[g] if B.dash>0 then B.x+=B.dvx*df B.y+=B.dvy*df B.dash-=dt elseif not busy then local mv=P[1] if mv>0 and d>P[2] then movefoe(B,px,py,mv*sm) end end B.acd-=dt if B.acd<=0 and not busy then local A=P if g==7 then A=JACT[B.mode] end if B.shield or B.dash>0 or B.waves>0 then A=nil end if A and A[4]>0 then doact(A,a) B.acd=A[3] end end if B.pend then B.ptm-=dt if B.ptm<=0 then local p=B.pend B.pend=nil if p==2 then local da=ap(B) local sp=min(B.dsp,(d+8)/21) B.dvx,B.dvy=cos(da)*sp,sin(da)*sp B.dash=.35 elseif p==3 then if d<48 then hurt(18) end end end end B.x=cl(B.x,16,752) B.y=cl(B.y,16,752) end
function spawnactor(x,y) local a={x=x,y=y,hp=3,inv=0,a=rnd(),dead=false} add(ac,a) return a end
function killactor(a,m) if a.dead then return end a.dead=true if m then kadd(-9) ban(m) else kadd(-3) ban("an innocent has fallen -3") end end
function updactors(dt) for a in all(ac) do a.inv=max(0,a.inv-dt) local fe=nearfoe(a.x,a.y,26) if fe then local fa=ang(a.x-fe.x,a.y-fe.y) a.x+=cos(fa)*.9*df a.y+=sin(fa)*.9*df else a.x+=cos(a.a)*.45*df a.y+=sin(a.a)*.45*df end if abs(a.x-384)>378 or abs(a.y-384)>378 then a.dead=true kadd(2,false) ban("an innocent passed safely +2") end if not a.dead and a.inv<=0 then for e in all(foes) do if e.hp>0 and dd(a,e)<10 then a.hp-=1 a.inv=.8 if a.hp<=0 then killactor(a) end break end end end if not a.dead and dp(a)<14 and btnp(5) then killactor(a,"you slew an innocent -9") end if a.dead then del(ac,a) end end end

function addupgrade(i) U[i]+=1 recalc() if i==6 then heal(12) end end

function placefx(chan) if chan then kadd(8,false) ban("prayer heard +8") else kadd(-8,true) local ow={} for i=1,10 do if U[i]>0 and U[i]<ucap(i) then add(ow,i) end end if #ow==0 then bmax+=12 recalc() heal(12) ban("+12 max hp") else addupgrade(rpick(ow)) ban("free upgrade") end ban("shrine smashed -8") end end
function places(dt) for P in all(PL) do if not P.done then if dp(P)>=26 then P.arm=true P.ch=0 P.on=false elseif P.arm then if btnp(5) then P.done=true P.on=false sfx(44) placefx(false) else if btnp(4) then P.on=true end if P.on then P.ch+=dt heal(maxhp*.1*dt) if P.ch>=2 then P.done=true P.on=false sfx(44) placefx(true) end end end else P.ch=0 end elseif dp(P)<26 then heal(maxhp*.04*dt) end end end
function dolock() lockform=karma>=30 and "trial" or (karma<=-30 and "war" or "feral") lockgod=1 for i=1,6 do local need=sun[i]==0 if lockform=="war" then need=blood[i]==0 elseif lockform=="feral" then need=need or blood[i]==0 end if need then lockgod=i break end end ban(GN[lockgod].." approaching") for i=1,6 do spawnfoe(picktype()) end end
function events(dt) if tmin>lastr then lastr=tmin for P in all(PL) do if not P.on or P.done then P.done=false P.ch=0 P.arm=dp(P)>=26 end end if not asc then if tmin==1 then spawnfoe(7,104,576) spawnfoe(7,152,624) ban("the roadside shrine wakes") elseif tmin==2 then spawnfoe(9) ban("mini-boss: the brute") for i=1,6 do spawnfoe(picktype()) end elseif tmin==3 then dolock() elseif tmin==4 and not B then spawnboss(lockgod,lockform) end end end if asc then if not B and ascidx<=6 and tsec>=ascnext then spawnboss(ascidx,"trial") ascnext+=25 elseif not B and ascidx>6 and not judgespawned and tsec>=160 then judgespawned=true spawnboss(7,"asc") end return end nextinn-=dt if nextinn<=0 then nextinn=8 if #ac<5 then local sa=rnd() local na=spawnactor(mid(16,px+cos(sa)*105,752),mid(16,py+sin(sa)*105,752)) na.a=ang(px-na.x,py-na.y)+rnd(.08)-.04 end end cht-=dt if cht<=0 then cht=45 addpick("chest",40+rnd(688),40+rnd(688)) ban("a chest has appeared somewhere") end end
function updpick(dt) for p in all(pk) do local d=dp(p) if p.k=="ess" then if d<mag then local a=ap(p) p.x+=cos(a)*3.5*df p.y+=sin(a)*3.5*df end if d<7 then sfx(41) gainxp(p.v) fedt=0 del(pk,p) end elseif p.k=="mark" then if d<9 then sfx(41) del(pk,p) if won then entertally("boss") return end end elseif p.k=="chest" then if d<10 then del(pk,p) openchoices(3,"chest") return end end end end

function openchoices(n,src) sfx(40) local pool={} for i=1,10 do if U[i]<ucap(i) then add(pool,i) end end if #pool==0 then heal(25) ban("nothing left to learn: healed 25") state="play" return end ch=pickn(pool,min(n,#pool)) chsrc=src sel=1 state="level" end
function navc(c,n) if btnp(0) or btnp(2) then c-=1 end if btnp(1) or btnp(3) then c+=1 end return c<1 and n or c>n and 1 or c end
function updchoice() sel=navc(sel,#ch) if btnp(4) or btnp(5) then local src=chsrc addupgrade(ch[sel]) if src=="level" and lvlq>0 then lvlq-=1 openchoices(form==3 and 4 or 3,"level") else state="play" end end end
function setmodal(t,l,o,cb) modal={t=t,l=l,o=o,cb=cb,sel=1} state="modal" end
function docb(cb,s) if cb=="rival" then if s==1 then kadd(12) state="play" else kadd(-12) openchoices(3,"free") end elseif cb=="final" then if s==1 then state="rebirth" else state="ending" end end end
function updmodal() modal.sel=navc(modal.sel,#modal.o) if btnp(4) or btnp(5) then docb(modal.cb,modal.sel) end end
function entertally(r) if state=="tally" then return end won=r=="boss" music(won and 4 or 5) diss=0 saved={} for i=1,10 do saved[i]=(U[i]+1)\2 dset(39+i,saved[i]) end mkcarry() lastk=flr(karma) dset(32,lastk+100) state="tally" end
function updtally() diss+=.015 if diss>=1 and btnp(4) then state="rebirth" music(0) end end
-- main update
function updateplay(dt) tsec+=dt tmin=flr(tsec/15) df=dt*60 bant=max(0,bant-dt) pinv-=dt fedt+=dt local mx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0) local my=(btn(3) and 1 or 0)-(btn(2) and 1 or 0) mvflag=false if mx~=0 or my~=0 then local l=sqrt(mx*mx+my*my) face=ang(mx,my) local sp=spd px=cl(px+mx/l*sp*df,10,758) py=cl(py+my/l*sp*df,10,758) mvflag=true wph+=.14 end events(dt) if state~="play" then return end places(dt) local cap=min(30,8+5*tmin) if not B and not asc then spawnt-=dt if spawnt<=0 and #foes<cap then spawnfoe(picktype()) spawnt=max(.22,1.05-.16*tmin) end end for e in all(foes) do if e.hp>0 then updfoe(e,dt) end end sweepfoes() updboss(dt) updactors(dt) attacks(dt) sweepfoes() updpp(dt) updep(dt) local inz=false for z in all(zn) do if z.wn>0 then z.wn-=dt else z.b-=dt if z.k==1 then if dp(z)<z.r then inz=true pacc+=dt if pacc>=.5 then pacc=0 hurt(z.d*.5,true) end end elseif abs(px-z.x)<z.w then hurt(10*dt,true) end end if z.b<=0 then del(zn,z) end end if not inz then pacc=0 end updpick(dt) if state~="play" then return end for e in all(foes) do if e.hp>0 and dp(e)<min(e.r,10)+6 then hurt(e.dmg) end end if B and dp(B)<22 then hurt(15) end if form==5 and fedt>5 and hp>maxhp*.3 then hp=max(maxhp*.3,hp-.5*dt) end if regen>0 then heal(regen*dt) end if hp<=0 then entertally("death") return end if pendingrival then pendingrival=false setmodal("the rival soul",{"the brute falls.","his soul hovers, waiting.","mercy: +12 karma.","execute: -12 karma,","and steal an upgrade."},{"mercy","execute"},"rival",1) return end if pendingfinal then pendingfinal=false setmodal("the empty throne",{"the judge is defeated.","the throne sits empty,","the wheel is still.","sit: free play with gods.","step off: the true ending."},{"sit on the throne","step off the wheel"},"final",1) return end if lvlq>0 then lvlq-=1 openchoices(form==3 and 4 or 3,"level") end end
-- drawing
function drawstr() for i=1,#ANC,2 do local x,y=ANC[i],ANC[i+1] for j=1,#LAY do local n=LAY[j] spr(abs(n),x+(j-1)%3*8,y+(j-1)\3*8,1,1,n<0) end end end
function drawworld() camx=cl(px-64,0,640) camy=cl(py-64,0,640) camera(camx,camy) cls(3) for gy=flr(camy/8),flr((camy+120)/8)+1 do for gx=flr(camx/8),flr((camx+120)/8)+1 do local n=gy*96+gx local v=band(shr(peek(8192+n\4),(n%4)*2),3) if v==1 then pset(gx*8+3,gy*8+4,(gx+gy)%3==0 and 4 or 11) elseif v>1 then spr(149+v,gx*8,gy*8) end end end drawstr() rectfill(0,600,767,607,4) rect(1,1,766,766,5) for P in all(PL) do drw(106,P.x,P.y,16,16,0) circ(P.x,P.y,P.done and 26 or 26-P.ch*13,P.done and 1 or 11) if not P.done and dp(P)<44 then print("z: pray  x: smash",P.x-34,P.y-18,7) end end for z in all(zn) do if z.k==1 then if z.wn>0 then circ(z.x,z.y,z.r,8) else drw(6,z.x,z.y,16,16,0) end elseif z.wn>0 then line(z.x,0,z.x,767,10) else rectfill(z.x-z.w,0,z.x+z.w,767,10) end end for p in all(pk) do if p.k=="chest" then drw(108,p.x,p.y,16,16,0) else if p.k=="mark" and markearned==129 then pal(10,8) spr(128,p.x-4,p.y-4) pal() else spr(PKS[p.k],p.x-4,p.y-4) end end end for a in all(ac) do drw(107,a.x,a.y,16,16,0,cos(a.a)<0) circfill(a.x,a.y-11,2,10) if dp(a)<16 then print("x: slay",a.x-10,a.y-19,8) end end for e in all(foes) do local k=e.k if k==10 then pal(5,9) pal(6,10) end drw(FSN[k],e.x,e.y,e.w,e.h,FSF[k],cos(e.face)<0) pal() end if B then local x,y=B.x,B.y local g=B.god if B.bm==0 then spr(B.b1,x-8,y-16,2,4,g==5 and cos(B.tm*.3)<0,g==5 and sin(B.tm*.3)<0) else drw(B.b1,x,y,32,32,B.bm) pal() end if g==2 and B.vac>0 then sspr(64,112,16,16,x-16,y-6,16,16) sspr(64,112,16,16,x,y-6,16,16,true) end if B.tele>0 then circ(x,y+13,3+B.tele*9,8) end if B.tr[1]>0 then for i=0,B.tr[1]-1 do local sa=B.tm*.4+i/B.tr[1] circfill(x+cos(sa)*B.tr[2],y+sin(sa)*B.tr[2],1,7) end end end if not (pinv>0 and fr%4<2) then drawform(form,px,py,face,avt,mvflag,true) end if avt>0 then local fx,fy=cos(face),sin(face) spr(111,px+fx*16-4,py+fy*16-4,1,1,fx<0,fy<0) end for p in all(pp) do line(p.x-p.dx*2,p.y-p.dy*2,p.x,p.y,10) pset(p.x,p.y,7) end for p in all(ep) do if p.k=="bone" then spr(133,p.x-4,p.y-4) elseif p.k=="poke" then spr(109,p.x-8,p.y-4,2,1,p.dx<0) else circfill(p.x,p.y,2,p.k=="ember" and 9 or 7) end end camera() end
function bar(y,h,f,c) rectfill(2,y,50,y+h,1) rectfill(2,y,2+48*f,y+h,c) end
function drawhud() rectfill(0,0,127,15,0) bar(2,3,max(0,hp/maxhp),8) bar(7,2,min(1,xp/need),12) print("l"..lvl,53,2,7) print((karma>0 and "+" or "")..flr(karma),104,2,karma>0 and 11 or (karma<0 and 8 or 7)) for q=34,94,20 do pset(q,13,q<64 and 8 or 7) end line(64+karma\2,12,64+karma\2,14,10) if state=="play" then rectfill(0,16,127,17,1) rectfill(0,16,127*min(1,tsec/60),17,12) for q=1,3 do pset(q*31.75,16,7) end end if B then rectfill(14,120,114,124,1) rectfill(14,120,14+100*max(0,B.hp/B.mh),124,8) end if bant>0 then local w=#bantxt*4+6 rectfill(64-w/2,20,64+w/2,29,0) print(bantxt,64-#bantxt*2,22,10) end end
function drawchoice() box(9,30,119,100) print(chsrc=="level" and "level up: choose" or "choose an upgrade",16,34,7) for i=1,#ch do local y=48+(i-1)*14 spr(UI[ch[i]],14,y-2) print((i==sel and "> " or "  ")..UN[ch[i]].." x"..U[ch[i]],26,y,7) end end
function drawmodal() box(9,36,119,96) print(modal.t,16,40,10) for i=1,#modal.l do print(modal.l[i],16,48+(i-1)*6,7) end for i=1,#modal.o do print((i==modal.sel and "> " or "  ")..modal.o[i],16,80+(i-1)*7,7) end end
function drawtally() box(9,14,119,116) local ts=flr(tsec) print((won and "god felled  " or "you died  ")..flr(ts/60)..":"..(ts%60<10 and "0" or "")..ts%60 .."  level "..lvl,16,20,won and 10 or 8) print("kills "..kills.."  karma "..flr(karma),16,27,7) if markearned>0 then if markearned==129 then pal(10,8) end spr(128,16,36) print(marktxt,26,38,7) elseif marktxt~="" then print(marktxt,16,36,7) end if crownnote~="" then print(crownnote,16,46,10) end local pf=pform(flr(karma)) print("next: "..(pf>0 and FN[pf] or FN[ladder(flr(karma))]),16,55,7) if carry>0 then print("kept: "..carry.." upgrades",16,66,11) end print("z: be reborn",16,106,5) end

function drawrebirth() cls(0) local pf=pform(lastk) local nf=pf>0 and pf or lives==0 and 1 or ladder(flr(lastk)) if dfm>0 then nf=dfm end drw(FH[nf],64,38,32,32,FDS[2*nf-1]) local nm=FN[nf] print(nm,64-#nm*2,58,7) print("bosses defeated",34,67,5) for r=0,1 do if r==1 then pal(10,8) end for i=1,6 do if (r==0 and sun or blood)[i]==1 then spr(128,22+i*9,76+r*12) end end end pal() if crown(sun) then spr(130,8,76) end if crown(blood) then spr(131,104,88) end print("f:"..(dfm==0 and "-" or FN[dfm]).." b:"..(dbs==0 and "-" or GN[dbs]),8,102,5) print(crown(sun) and crown(blood) and "z: normal life   x: ascension" or "z: begin life",14,122,10) end
function drawending() cls(0) print("you step off the wheel",22,40,10) print("no more marks. no more hunger.",14,56,7) print("the gods keep their thrones.",20,66,7) print("you keep the silence after.",22,76,7) print("z: return",48,100,5) end
-- entry
function _init() wph=0 dfm,dbs=0,0 loadsave() state="rebirth" music(0) end
SU={level=updchoice,modal=updmodal,tally=updtally}
function _update60() fr+=1 if state=="rebirth" then dfm=(dfm+(btnp(1) and 1 or 0)-(btnp(0) and 1 or 0))%8 dbs=(dbs+(btnp(2) and 1 or 0))%8 if btnp(5) and crown(sun) and crown(blood) then startlife(true) elseif btnp(4) then startlife(false) end elseif state=="ending" then if btnp(4) then state="rebirth" end else local f=SU[state] if f then f() else updateplay(1/60) end end end
function _draw() pal() if state=="rebirth" then drawrebirth() return end if state=="ending" then drawending() return end drawworld() drawhud() if state=="level" then drawchoice() end if state=="modal" then drawmodal() end if state=="tally" then if diss<1 then for i=1,diss*520 do pset(rnd(128),rnd(128),0) end else drawtally() end end end
__gfx__
000070007000700000000aaaaaaa0000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000
000070077700700000000aaa8aaa000000000000c00000000900000800000000000000000000000000000000000000000000000aa00000000000000000000000
000777777777770000000aaaaaaa00000000000cac00000000000089000000000000000000000000000000000000000000a0000aa0000a000000000007772277
000777777777770000000004440000000000000cac00000008000089000000000000000000000000000000000000000000aa00aaaa00aa000000000007772277
00007717771770000000000777000000000000ccacc0000008000899000000000000000000000000000000000000000000aa00aaaa00aa000000000022722227
0000718171817000000000777770000000000cc7a7cc000008800899000000000000000000000000000000000000000000aaaaaaaaaaaa000000000022722227
0000771777177000000007778777000000000cc7a7cc00008880899900000000000000000000000000000000000000000aaaaaaaaaaaaaa00000000022222222
000077771777700000000778187700000000cc77a77cc0008888999900000000000000000000000000000000000000000aaaaaaaaaaaaaa00000000022222222
000007777777000000aaa7788877aaa00000cc7cac7cc0008889999a000000000000000000000000000000000000000009999999999999900000000022222222
000000777770000000aaa7778777aaa00000ccc7a7ccc000889999aa000000000000000000000000000000000000000009999999999999900000000022222222
000002222222000000aaaa77777aaaa00000cc77a77cc000899999aa000000000000000000000000000000000000000000000ffffff000000000000022222222
000222222222220000000077776000000000cc77a77cc00099999aaa00000000000000000000000000000000000000000000ffffffff00aaa000000022222222
00222222222222200000007676600000000cc77cac77cc009999aaaa0000000000000000000000000000000000000000000f11ffff11faaaaa00000022228888
00722222222227200000007676600000000cccc7a7cccc00099aaaa7000000000000000000000000000000000000000000fff11ff11ffaa8aa00000022888882
00722222222227200000007676600000000cc777a777cc0009aaaa77000000000000000000000000000000000000000000fff1ffff1ffaaaaa00000088888882
007222227222272000000076a6600000000cc777a777cc0000aaaa77000000000000000000000000000000000000000000ffff1ff1ffffaaa000000088888882
02722222722227220000007676600000000cc77cac77cc0000000000000000000000000000000000000000000000000000ffffffffffff040000000000000000
027227777777272200000076766000000000ccc7a7ccc000000000000000000011000011000000000000000000000000000fff1111fff00400000000000000aa
072222227222227200000076766000000000cc77a77cc0000000000000000000011001100000000000000000000000000000ffffffff00040000000000000aaa
07222222a222227200000076766000000000cc77a77cc00000000000000000000000000000000000000000000000000000000ffffff000040000000000000a1f
072227788877227000000076a66000000000cc7cac7cc00000000000000000000010010000000000000000000000000000011111111110040000000000000aaf
0722222282222270000000767660000000000cc7a7cc00000000000000000000000000000000000000000000000000000071111aa11117040000000000000aaf
072222227222227000000076766000000000ccc7a7ccc0000000000000000000001111000000000000000000000000000011111aa11111040000000000000aa7
7072277777772727000000767660000000000cc7a7cc00000000000000000000000000000000000000000000000000000011111aa11111040000000000000aa7
00222222722222200000006676600000000000ccacc000000000000000000000000000000000000000000000000000000011111aa11111040000000000000aa7
0022222272222220000000667660000000000cccaccc00000000000000000000000000000000000000000000000000000111111aa11111140000000000000aa7
002222227222222000000006660000000000c00cac00c0000000000000000000000000000000000000000000000000000111111aa11111140000000000000aa7
0002222222222200000000066600000000000000a00000000000000000000000000000000000000000000000000000001111111aa11111140000000000000077
0002220222022200000000006000000000000000a00000000000000000000000000000000000000000000000000000001111111aa11111140000000000000077
0002200222002200000000006000000000000000a00000000000000000000000000000000000000000000000000000001111111aa11111140000000000000077
0002000020000200000000000000000000000000a00000000000000000000000000000000000000000000001000000011111111aa11111141000000000000077
00000000200000000000000000000000000000000000000000000000000000000000000000000000000000010000000111111111111111111000000000000077
000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee0000000000a000000000600000a0
04400444000444440000000000404000000070000000000000000000000000000000000000000000000000aa00e00000eeeee000000000af00000000060000af
0000044404400444000000000049990000007000000000000000000000000000000000000000000000000aaa0e7ee000ee77ee0000000aaa0000000000400aaa
000004440000044400000000009999940007770800000000000000000000000000000000000e000000000a0feee7eeee0ee77ee000000f8f0000000060040f8f
02000444000004440000000009999999000777880000000000000000000000000000000000eee00000000aafeee77eee0ee777ee06000fff0000000060004fff
002204420000044290000000099991f90000088a0000000000000000000000000000000000eee00000000aafeee7777e0ee7777e060000ff00000000060004ff
00002492000024920900099999999ff8000008880000000000000000000000000000000000dedd0000000aa70ee7777000e777ee006440110000000000400041
00004992002249920409999999999fff00000088000000000000000000000000e000ddddddddd8d000000aa70ee777e0000ee7ee000004440000000000044994
000049920200499200999499999999f000000228000000000000000000000000e0ddddddddddddd200000aa70ee777e00000e000000009990000000000000499
02222992022229920099999999999900000022220000000000000000000000000ddddddddddddd7000000aa700eeeee000000000060009990000000000000949
00004992020049920099994949999900000222290000000000000000000000000dddddddddddd07000000aa700eee00000000000060004440000000000000994
000044920022449200099999999990000002222200000000000000000000000000ddddddddd0000000000777000e000000000000006441110000000000000111
0000244200002442000049999994040000202229000000000000000000000000000ddddddd000000000007770000000000000000000001110000000000000111
0022044200000442000040400004040000000229000000000000000000000000000d00d00d0000000000077a0000000000000000000011110000000000001111
0200000200000002000040400004040000000022000000000000000000000000000d00d00d000000000007a70000000000000000000011110000000000001111
00000000000000000000404000040400000000020000000000000000000000000000000000000000000000000000000000000000000011110000000000001111
000000a000000000000000dd000000000000000000000008000000000000000a000000660000000000000000000000000000000000000000000000000a700000
000000af0000004400000dd800000000000000770000555800006666000000070000066600000000066666660000004400000000000000000000aaaa007a0000
00000aaa0000044400000ddd0000000c000007770000558800066666000000770000666600000000053555550000044400000000000000000000a00000070000
00000f8f00000f1f000000dd0000000000007777000055550006666600a0007c0000660600000000055553550000044400000000aaaaaaaaaaaaa0000007a000
00000fff00000fff0000000d00000bbb00007077000055ff00666666000007cc00006660000000000055011100000f0f00fffffa999999999999aaaa0007a000
000000ff000000ff0000000d0c00bbbb0000777700000fff00555555000077cc00006600000000000055011100000fff004444aa000000000000a00000770000
0000000100000011000000dd000bbbbb00000767005558ff0056116600007ccc00006660000000000055011a000000ff004444a0000000000000aaaa077a0000
000044440000001100000dee00bbbbbb00000767055555ff005666660007711c0000666600000000005501190000cccc004444a000000000000000000a000000
64440099000000110000ddee00bbbbbb00000767055555ff0056656600077ccc0060666600000000005501910000cccc0044444a00999499999999f000000000
00000099000001110000deee00bbb0bb0000000605552225005665660a007cc1000666660000000000550111000ccccc0044444a009999999999990000000000
00000044000001110000deee00bbbbbb00006666005522250056661600007ccc000655550000000000550111000c44440044404a009999494999990000000000
00444411000001110000deee00bbb0bb000000060000222a005666660000077c000666660000000000550000000c05500044444a000999999999900000000000
64000011000001110000deee00bbb0bb00006666000022250055611100000777000665550000000005555555000f05500044444a000409999990004000000000
00000111000011110000ddee00000b00000000060000222500066666000000cc000666660000000005555555000005500044404a000400040040004000000000
000001110000111100000dee000000000000666600002555000666660000000c000660660000000055555555000005500044444a000400040040004000000000
0000011100001111000000d0000000000000000000000550000555550000000c0066000600000000666666660000000000000000000400040040004000000000
0009900000000000a00aa00a80088008000cc0007700007700070000000006000000000000080000000aaa000880880077777777000000000000000044444440
0900009000000000aaaaaaaa2282282200cccc00777007770007000000040600000000b00800008000a770008888888055555555000ee0000000000004444400
000aa00000000000aaaaaaaa222222220c7cccc00777777000076000004006000000b00b0099090000aaaaaa8e88888056555565000ee00000000000004a4000
90a7aa0900000000aaaccaaa22288222ccccccc0000770000007600004400600700b00b0000aa0000aaaaaa088888880555555550eeeeee000000000000a0000
90aaaa0900000000aaaaaaaa222222220ccccc000006600000aaa0000440060070b07000809aa0900aaaaa0008888800055555500eeeeee000000000004a4000
000aa00000000000000000000000000000ccc000077777700004000000400600700b00b000900900aaaa00000088800005555550000ee0000000000004a4a400
09000090000000000000000000000000000c00007770077700040000000406000000b00b0800908000a000000008000000555500000ee0000000000044444440
0009900000000000000000000000000000000000770000770009000000000600000000b0000000000a0000000000000000055000000000000000000000000000
07700770000000098888888844444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000
088008800000009898989898ffffffffffffffffff4444ff44ffffff0000000000e0a00000000000000000000000000000000000000000000000000000000000
088008800000098888888888ffffffffff4444ffff4224ff44ffffff00b00b000b0b0b0000000000000000000000000000000000000000900900000000000000
088008800000989889898989f7ffffffff4aa4ffff4224ff44ff7fff00b03b0000b7b00000000000000000000000000000000000000009999990000000000000
088008800009888888888888ffffffffff4444ffff4444ff44ffffff0b3b03b00b0b0b0000000000000000000000000000000000009999999999990000000000
008888000098888898989898ffffff7fff4aa4ffff444aff44ffffff0b3b03b00000000000000000000000000000000000000000099994444449999000000000
000880000989889888888888ffffffffff4444ffff4444ff44ffffff000000000000000000000000000000000000000000000000999449999994499900000000
000000009888888822222222ffffffffffffffffff4444ff44ffffff000000000000000000000000000000000000000000000009999999999999999990000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099499999fffff9999499000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099949979fffffff999499900000
000000000000000000000000000000000000000000000aaaaaa0000000000000000000000000000000000000000000000000999499997ffffffff99949490000
000000000000000000000000000000000000000000aaaaaaaaaaaa00000000000000000000aa00000000aa000000000000009949999f474fff444f9994990000
00000000000000000000000000000000000000000aaaaaaaaaaaaaa000000000000000000aa0aaaaaaaa0aa00000000000009949999fff7fffffff9994990000
000600000000000000000000000060000000070aaaaaa000000aaaaaa07000000000000aaa0aa000000aa0aaa00000000009949999fff1fffff1fff999499000
00100000002200000000220000000100000000aaaaa0044444400aaaaa000000000000aaaaa0044444400aaaaa0000000099949999fffffffffffff999499900
0000000002222000000222200000000000000aa880044000000440088aa0000000000aa8a00040000004000a8aa000000009949999fffffffffffff999449000
0000000022222200002222220000000000000aaa0040000000000400aaa0000000000aaa0000000000000000aaa000000009949999fffff222fffff999499000
00000000222a22000022a222000000000000aaa004000000000000400aaa00000000aa00040000000000004000aa00000099949999ffffff2ffffff999499900
00000000222122000022122200000000000aaaa040000000000000040aa9a000000aaaa040000000000000040aaaa0000009949999ffffff4ffffff999499000
00000000022222222222222000000000000aaa04000777777777770040aaa000000aaa04000888008008880040aaa00000009949999f4fff4fff4f9994990000
00000000222222222222222200000000000aaa04007777777777777040aaa000000aaa04008777788877778040aaa00000009949999f4fff4fff4f9994490000
0000002222222222222222222200000000aaa0400077777888777770040aaa0000aaa0400087788888887780040aaa00000099949999f444f444f99949990000
00002222b22222222222222b2222000000aaa0400777778888877777040aaa0000aaa0400877788888887718040aaa000000099949999fffffff999499900000
0002211777177717717771777112200000aaa0400777788888887777040aaa0000aaa0400877888888888771040aaa0000000099499999fffff9999499000000
0022222777277727727772777222220000aaa0407a7778888888777a040aaa0000aaa0408777888888888771040aaa0000000009999999999999999990000000
0022222272227222222722272222220000aaa0400777788888887777040aaa0000aaa0400877888888888778040aaa0000000000999949999994499900000000
022222222222ffffffff22222222222000aaa0400777778888877777040aaa0000aaa0400877788888887778040aaa0000000000999994444449999990000000
022222222ffffffffffffff222222220000aaa04007777788877777040aaa000000aaa04008778888888778040aaa00000000009949499999999949499000000
02222222ffffffffffffffff22222220000aaa04007777777777777040aaa000000aaa04008777788877778040aaa00000000009949499999999949499000000
0222222ffffffffffffffffff2222220000aaaa040077777777777040aaaa000000aaaa040088888888888040aaaa00000000009949499900909949499000000
022222ffffffffffffffffffff2222200000aaa0040000000000004009aa00000000aa00040000000000004000aa000000000000949490000000949490000000
002222ffffffffffffffffffff22220000000aaa0040000000000400aaa0000000000aaa0000000000000000aaa0000000000000099900000000099900000000
0022d2ffffffffffffffffffff22220000000aa880044000000440088aa0000000000aa8a00040000004000a8aa000000000000aa00000000000000000000000
00022dffffffffffffffffffff222000000000aaaaa0044444400aaaaa000000000000aaaaa0044444400aaaaa00000000000aaaaaa000000000000000000000
0022222ffffffffffffffffff22222000000070aaaaaa000000aaaaaa07000000000000aaa0aa000000aa0aaa00000000000aaaaaaaa00000000000000000000
02222222ffffffffffffffff22222220000000000aaaaaaaaaaaaaa000000000000000000aa0aaaaaaaa0aa000000000000aaaaaaaaaa0000000000000000000
222222222ffffffffffffff2222222220000000000aaaaaaaaaaaa00000000000000000000aa00000000aa0000000000000aaaaa7aaaa0000000000000000000
222222220002ffffffff2000222222220000000000000aaaaaa000000000000000000000000000000000000000000000000a111aa111a0000000000000000000
022222200000000000000000022222200000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaa0000000000000000000
0022220000000000000000000022220000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa00000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999999999000000000000000000
000000000040400000000000000000000000000000000000000000000000000000000000000000000000000000000000009999aaaa4499000000000000000000
000000000049990000000000000000000000000000000000000000000000000000000777077722770000000000000000009999aaaa4499000000000000000000
00000000009999940000000000000000000000000000000000000000000000000000077707772277000000000000000000999999994499000000000000000000
00000000099999990000000000000000000000000000000000000000000000000000007222722227000000000000000000999999999999000000000000000000
90000000099991f90000000000000000000000000000000000000000000000000000007222722227000000000000000009999999999999900000000000000000
0900099999999ff80000000000000000000000000000000000000000000000000000022222222222000000000000000009999999999999900000000000000000
0409999999999fff0000000000000000000000000000000000000000000000000000222222222222000000000000000000111111111111000000000000000000
00999499999999f00000000000000000000000000000000000000000000000000002222222222222000000000000000000000000000000000000000000000000
00999999999999000000000000000000000000000000000000000000000000000002222222222222000000000000000000000000000000000000000000000000
00999949499999000000000000000000000000000000000000000000000000000002222222222222000000000000000000000000000000000000000000000000
00099999999990000000000000000000000000000000000000000000000000000002222222222222000000000000000000000000000000000000000000000000
00040999999000400000000000000000000000000000000000000000000000000002222222228888000000000000000000000000000000000000000000000000
00040004004000400000000000000000000000000000000000000000000000000000222222888882000000000000000000000000000000000000000000000000
00040004004000400000000000000000000000000000000000000000000000000000022288888882000000000000000000000000000000000000000000000000
00040004004000400000000000000000000000000000000000000000000000000000002288888882000000000000000000000000000000000000000000000000
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
