const fs=require('fs'),vm=require('vm'),assert=require('assert');
const html=fs.readFileSync('dodam-clock-did.html','utf8');
for(const m of html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)) new vm.Script(m[1]);
const start=html.indexOf('  function mealDateLabel('),end=html.indexOf('  function restoreMealCache(',start);
function run(rows,error){
 const today=Date.UTC(2026,9,22,3), RealDate=Date;
 class FixedDate extends RealDate {constructor(...a){super(...(a.length?a:[today]));}}
 const ctx={Date:FixedDate,DAY:86400000,now:()=>today,ymd:d=>new RealDate(+d+32400000).toISOString().slice(0,10).replace(/-/g,''),trim:x=>String(x||'').trim(),activeDay:'2026-10-22',mealsBusy:false,meals:[],nextMeals:[],mealDate:'',nextMealDay:'',schoolInfo:cb=>cb(null,{}),neis:(name,params,cb)=>{assert.equal(params.MLSV_FROM_YMD,'20261022');cb(error,rows);},writeCache:()=>{},readCache:()=>null,validMeals:Array.isArray,refreshBoard:()=>{}};
 ctx.window={DodamTime:{now:()=>today}};
 vm.createContext(ctx);vm.runInContext(html.slice(start,end)+';loadMeals();',ctx);return ctx;
}
const row=(date,menu)=>({MLSV_YMD:date,DDISH_NM:menu,MMEAL_SC_NM:'중식'});
let c=run([row('20261027','화요일밥'),row('20261026','월요일밥')]);assert.equal(c.mealDate,'20261026');assert.equal(c.nextMealDay,'20261027');assert.equal(c.mealDateLabel(c.mealDate),'10월 26일(월)');
c=run([row('20261022','오늘'),row('20261023','내일')]);assert.equal(c.mealDateLabel(c.mealDate),'오늘');assert.equal(c.nextMealLabel(),'내일');
c=run([]);assert.equal(c.meals.length,0);assert.equal(c.mealsBusy,false);
c=run([],new Error('offline'));assert(c.mealError);assert.equal(c.mealsBusy,false);
console.log('PASS: inline syntax; holiday gap; sorted meals; actual date labels; empty result; network failure');
// A legacy browser must recover from failed JSON XHR via same-origin script.
const transport=html.slice(html.indexOf('/* Shared GET transport'),html.indexOf('/* BEGIN CONFIG */'));
let attempts=0, scripts=0;
const win={location:{protocol:'https:',host:'example.test'},JSON,XMLHttpRequest:function(){this.open=()=>{};this.send=()=>{attempts++;this.status=0;this.readyState=4;this.onreadystatechange();};}};
const parent={appendChild(script){scripts++;script.parentNode=parent;win.TEST_RESPONSE={items:[1]};script.onload();},removeChild(){}};
win.document={createElement:()=>({}),getElementsByTagName:()=>[parent]};
win.DodamTime={now:Date.now};
vm.runInNewContext(transport,{window:win,setTimeout,clearTimeout,Error});
let called=0;win.DodamNet.readJSON('mirror.json','mirror.js','TEST_RESPONSE',(err,data)=>{assert.ifError(err);assert.equal(data.items[0],1);called++;});
assert.equal(attempts,1);assert.equal(scripts,1);assert.equal(called,1);
console.log('PASS: legacy JSON failure recovers through data script, callback once');
// IE9 uses XDomainRequest for the external time source; elapsed time ignores PC changes.
const timeSource=html.match(/<script id="dodam-standard-time">([\s\S]*?)<\/script>/)[1];
let elapsed=50, legacyRequests=0;
const legacyTimeWindow={location:{protocol:'https:',hostname:'display.test'},performance:{now:()=>elapsed},XDomainRequest:function(){this.open=()=>{};this.send=()=>{legacyRequests++;this.responseText=JSON.stringify({year:2026,month:10,day:24,hour:3,minute:0,seconds:32,milliSeconds:0,timeZone:'UTC'});this.onload();};}};
legacyTimeWindow.parent=legacyTimeWindow;
vm.runInNewContext(timeSource,{window:legacyTimeWindow,document:{documentMode:9},JSON,Date,setTimeout:()=>1,clearTimeout:()=>{},setInterval:()=>1});
assert.equal(legacyRequests,1);assert(legacyTimeWindow.DodamTime.synchronized());
assert.equal(legacyTimeWindow.DodamTime.now(),Date.UTC(2026,9,24,3,0,32));elapsed+=1000;
assert.equal(legacyTimeWindow.DodamTime.now(),Date.UTC(2026,9,24,3,0,33));
const parentTimeWindow={parent:{SchoolTime:{now:()=>1234,synchronized:()=>true}}};
vm.runInNewContext(timeSource,{window:parentTimeWindow,document:{},JSON,Date,setTimeout:()=>1,clearTimeout:()=>{},setInterval:()=>1});
assert.equal(parentTimeWindow.DodamTime.now(),1234);assert(parentTimeWindow.DodamTime.synchronized());
console.log('PASS: legacy time transport, monotonic elapsed time and embedded KRISS clock delegation');
const requestWeatherSource=html.slice(html.indexOf('  function requestWeather('),html.indexOf('  function weatherSlot('));
function weatherRequest(mode, mirror, directError, seed){
 const calls=[];const at=Date.UTC(2026,9,27,0);let result,count=0;
 const ctx={document:{documentMode:mode},DAY:86400000,now:()=>at,JSON,Error,request:(url,cb)=>{calls.push('external');cb(directError,directError?null:'{"current":{"temperature_2m":12}}');},window:{DODAM_WEATHER_SEED:seed,DodamNet:{states:{},readJSON:(json,script,key,cb)=>{calls.push('site');cb(mirror instanceof Error?mirror:null,mirror);}}}};
 vm.runInNewContext(requestWeatherSource,ctx);ctx.requestWeather('https://api.open-meteo.com/v1/forecast',(error,body,savedAt)=>{count++;result={error,body,savedAt}});assert.equal(count,1);return {calls,result};
}
const at=Date.UTC(2026,9,27,0), validWeather={savedAt:at-600000,data:{current:{temperature_2m:12}}};
let w=weatherRequest(9,validWeather,new Error('external blocked'));assert.deepEqual(w.calls,['site']);assert.equal(w.result.savedAt,validWeather.savedAt);
w=weatherRequest(9,{...validWeather,savedAt:at-2*86400000},new Error('blocked'));assert.deepEqual(w.calls,['site','external']);assert.equal(w.result.error.message,'사이트 날씨 자료 갱신 필요');
w=weatherRequest(9,new Error('404'),null);assert.deepEqual(w.calls,['site','external']);assert.ifError(w.result.error);
w=weatherRequest(undefined,validWeather,null);assert.deepEqual(w.calls,['external']);assert.ifError(w.result.error);
w=weatherRequest(9,new Error('missing'),new Error('blocked'),validWeather);assert.ifError(w.result.error);
console.log('PASS: IE site-first; expired site data; external recovery; modern direct; embedded recovery; callbacks once');

const slotSource=html.slice(html.indexOf('  function weatherSlot('),html.indexOf('  function weather(slot'));
const maintainSource=html.slice(html.indexOf('  function maintain('),html.indexOf('  function startData('));
const kst=(h,m=0,d=10)=>Date.UTC(2026,10,d,h-9,m);
let weatherNow=kst(8,29), attemptsAt=[];
const weatherSchedule={
 Date,HOUR:3600000,DAY:86400000,now:()=>weatherNow,seoul:d=>new Date(+d+9*3600000),
 document:{documentMode:9},window:{location:{protocol:'https:'},DodamTime:{now:()=>weatherNow}},
 dayKey:()=> '2026-11-10',activeDay:'2026-11-10',dataStarted:true,snapshot:null,
 weatherSavedAt:0,weatherAttemptSlot:0,weatherCheckedAt:0,weatherBusy:false,noticeBusy:true,
 weather(slot,siteOnly){
  attemptsAt.push([slot,siteOnly]);
  weatherSchedule.weatherAttemptSlot=slot;
  weatherSchedule.weatherCheckedAt=weatherNow;
  if(siteOnly){weatherSchedule.snapshot={};weatherSchedule.weatherSavedAt=weatherNow;}
 },
 renderBoard(){},diagnostics(){}
};
vm.runInNewContext(slotSource+maintainSource,weatherSchedule);
assert.equal(weatherSchedule.weatherSlot(kst(8,29)),kst(16,0,9));
assert.equal(weatherSchedule.weatherSlot(kst(8,30)),kst(8,30));
assert.equal(weatherSchedule.weatherSlot(kst(12)),kst(12));
assert.equal(weatherSchedule.weatherSlot(kst(16)),kst(16));
assert.equal(weatherSchedule.weatherSlot(kst(0,0,11)),kst(16));
for(const time of [kst(8,30),kst(8,31),kst(8,39),kst(8,40),kst(8,50),kst(12),kst(16)]) {
 weatherNow=time;weatherSchedule.maintain();
}
assert.deepEqual(attemptsAt,[[kst(8,30),false],[kst(8,30),true],[kst(12),false],[kst(16),false]]);
console.log('PASS: three Korea-time weather slots; delayed legacy publication check; no repeat after fresh feed');
