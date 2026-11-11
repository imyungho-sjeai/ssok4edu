using System;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using System.Web.Script.Serialization;
class MediaSources {
 static JavaScriptSerializer json=new JavaScriptSerializer{MaxJsonLength=10000000};
 static object gate=new object();static Dictionary<string,Tuple<DateTime,string>> cache=new Dictionary<string,Tuple<DateTime,string>>();
 static bool collecting=false;static DateTime contestsAt=DateTime.MinValue;static List<object> contests=new List<object>();static string contestError="";
 public static string Fetch(string url) {
  var r=(HttpWebRequest)WebRequest.Create(url);r.Timeout=20000;r.ReadWriteTimeout=20000;r.UserAgent="Mozilla/5.0 SchoolClock/4.0";r.AutomaticDecompression=DecompressionMethods.GZip|DecompressionMethods.Deflate;
  using(var response=r.GetResponse())using(var stream=response.GetResponseStream())using(var reader=new StreamReader(stream,Encoding.UTF8)) {var s=reader.ReadToEnd();if(s.Length>8000000)throw new Exception("응답이 너무 큽니다.");return s;}
 }
 public static string Get(string path,string query){if(path=="/api/channel-videos"){var dailyQuery=System.Web.HttpUtility.ParseQueryString(query);string id=dailyQuery["id"]??"",mode=dailyQuery["mode"]??"videos";if(!Regex.IsMatch(id,@"^UC[\w-]{22}$")||(mode!="videos"&&mode!="shorts"))throw new Exception("채널과 영상 종류를 확인하세요.");return DailyFetchCache.Get("youtube:"+id+":"+mode,()=>json.Serialize(Videos(id,mode)));}if(path=="/api/poster-contests")return ContestState();string key=path+query;lock(gate){Tuple<DateTime,string> hit;if(cache.TryGetValue(key,out hit)&&DateTime.UtcNow-hit.Item1<TimeSpan.FromMinutes(10))return hit.Item2;}
  var q=System.Web.HttpUtility.ParseQueryString(query);object value;
  if(path=="/api/channels")value=Channels(q["q"]??"");
  else if(path=="/api/channel-videos")value=Videos(q["id"]??"",q["mode"]??"videos");
  else if(path=="/api/culture-detail")value=CultureDetail(q["id"]??"");
  else if(path=="/api/culture")value=Culture(q["targets"]??"",q["region"]??"");
  else throw new Exception("잘못된 요청");
  string result=json.Serialize(value);lock(gate){cache[key]=Tuple.Create(DateTime.UtcNow,result);}return result;
 }
 static string Clean(string s){s=Regex.Replace(s,@"<(?:script|style)\b[^>]*>.*?</(?:script|style)>"," ",RegexOptions.Singleline|RegexOptions.IgnoreCase);return WebUtility.HtmlDecode(Regex.Replace(s,"<[^>]+>"," ")).Trim();}
 static List<object> Channels(string query){query=query.Trim();if(query.Length<1||query.Length>200)throw new Exception("채널명을 입력하세요.");var results=new List<object>();
  string id=Regex.Match(query,@"UC[\w-]{22}").Value;
  if(id!=""){results.Add(new{id=id,title=query});return results;}
  string html;
  if(query.StartsWith("@")||query.Contains("youtube.com/@")){
   string handle=query.StartsWith("@")?query:query.Substring(query.IndexOf("/@")+1).Split('/','?')[0];
   if(!Regex.IsMatch(handle,@"^@[\p{L}\p{N}_.-]+$"))throw new Exception("채널 핸들을 확인하세요.");
   html=Fetch("https://www.youtube.com/"+Uri.EscapeDataString(handle));
   var match=Regex.Match(html,"\"(?:externalId|channelId)\"\\s*:\\s*\"(UC[\\w-]{22})\"");id=match.Groups[1].Value;
   if(id=="")id=Regex.Match(html,"https://www.youtube.com/channel/(UC[\\w-]{22})").Groups[1].Value;
   if(id!="")results.Add(new{id=id,title=Clean(Regex.Match(html,@"<title>(.*?)</title>",RegexOptions.Singleline).Groups[1].Value).Replace(" - YouTube","")});
  }else{
   html=Fetch("https://www.youtube.com/results?search_query="+Uri.EscapeDataString(query)+"&sp=EgIQAg%253D%253D");
   foreach(Match m in Regex.Matches(html,"\"channelRenderer\"\\s*:\\s*\\{")){
    string block=html.Substring(m.Index,Math.Min(14000,html.Length-m.Index));id=Regex.Match(block,"\"channelId\":\"(UC[\\w-]{22})\"").Groups[1].Value;
    string title=Regex.Match(block,"\"title\":\\{\"simpleText\":\"((?:\\\\.|[^\"])*)\"").Groups[1].Value;
    if(title=="")title=Regex.Match(block,"\"title\":\\{\"runs\":\\[\\{\"text\":\"((?:\\\\.|[^\"])*)\"").Groups[1].Value;
    if(id!=""&&!results.Any(x=>json.Serialize(x).Contains(id)))results.Add(new{id=id,title=title==""?id:json.Deserialize<string>("\""+title+"\"")});if(results.Count>=10)break;
   }
  }
  if(results.Count==0)throw new Exception("채널을 찾지 못했습니다. @핸들 또는 채널 주소로 다시 검색하세요.");return results;
 }
 static object Videos(string id,string mode){if(!Regex.IsMatch(id,@"^UC[\w-]{22}$"))throw new Exception("채널을 선택하세요.");
  if(mode!="videos"&&mode!="shorts")throw new Exception("영상 종류를 선택하세요.");
  string html=Fetch("https://www.youtube.com/channel/"+id+"/"+mode+"?view=0&sort=dd&flow=grid");
  var initial=Regex.Match(html,@"(?:var\s+)?ytInitialData\s*=\s*\{");if(!initial.Success)throw new Exception("채널 영상을 읽지 못했습니다. 잠시 후 다시 확인하세요.");
  int begin=html.IndexOf('{',initial.Index),depth=0,end=begin;bool quoted=false,escape=false;
  for(;end<html.Length;end++){char ch=html[end];if(quoted){if(escape)escape=false;else if(ch=='\\')escape=true;else if(ch=='"')quoted=false;}else{if(ch=='"')quoted=true;else if(ch=='{')depth++;else if(ch=='}'&&--depth==0){end++;break;}}}
  object data=json.DeserializeObject(html.Substring(begin,end-begin)),selected=FindSelectedTab(data);if(selected==null)throw new Exception(mode=="shorts"?"이 채널에 공개 Shorts가 없습니다.":"이 채널에 공개 동영상이 없습니다.");
  var result=new List<object>();var used=new HashSet<string>();ReadVideos(selected,mode,result,used);
  if(result.Count==0)throw new Exception(mode=="shorts"?"표시할 Shorts가 없습니다.":"표시할 동영상이 없습니다.");return result.Take(10).ToArray();
 }
 static object FindSelectedTab(object node){var dict=node as Dictionary<string,object>;if(dict!=null){object t;if(dict.TryGetValue("tabRenderer",out t)){var tab=t as Dictionary<string,object>;if(tab!=null&&tab.ContainsKey("selected")&&Convert.ToBoolean(tab["selected"])&&tab.ContainsKey("content"))return tab["content"];}foreach(var v in dict.Values){var found=FindSelectedTab(v);if(found!=null)return found;}}else{var arr=node as object[];if(arr!=null)foreach(var v in arr){var found=FindSelectedTab(v);if(found!=null)return found;}}return null;}
 static string FindText(object node,string key){var d=node as Dictionary<string,object>;if(d!=null){object value;if(d.TryGetValue(key,out value)&&value is string)return (string)value;foreach(var v in d.Values){string text=FindText(v,key);if(text!="")return text;}}else{var a=node as object[];if(a!=null)foreach(var v in a){string text=FindText(v,key);if(text!="")return text;}}return "";}
 static void ReadVideos(object node,string mode,List<object> result,HashSet<string> used){var d=node as Dictionary<string,object>;if(d!=null){foreach(var kv in d){bool renderer=mode=="videos"?(kv.Key=="videoRenderer"||kv.Key=="lockupViewModel"):kv.Key=="shortsLockupViewModel"||kv.Key=="reelItemRenderer";if(renderer){string videoId=FindText(kv.Value,"videoId");if(videoId=="")videoId=FindText(kv.Value,"contentId");if(Regex.IsMatch(videoId,@"^[\w-]{11}$")&&used.Add(videoId)){var r=kv.Value as Dictionary<string,object>;object titleObj=null;if(r!=null)r.TryGetValue("title",out titleObj);string title=titleObj==null?FindText(kv.Value,"content"):FindText(titleObj,"text");if(title=="")title=FindText(titleObj,"simpleText");if(title=="")title=videoId;result.Add(new{id=videoId,title=title,published=DateTime.UtcNow.AddSeconds(-result.Count).ToString("o")});}}else ReadVideos(kv.Value,mode,result,used);}}else{var a=node as object[];if(a!=null)foreach(var v in a)ReadVideos(v,mode,result,used);}}
 static object FeedVideos(string id){
  string body=Fetch("https://www.youtube.com/feeds/videos.xml?channel_id="+id);
  var settings=new XmlReaderSettings{DtdProcessing=DtdProcessing.Prohibit,XmlResolver=null};XDocument doc;using(var xr=XmlReader.Create(new StringReader(body),settings))doc=XDocument.Load(xr);
  XNamespace a="http://www.w3.org/2005/Atom",yt="http://www.youtube.com/xml/schemas/2015";
  return doc.Descendants(a+"entry").OrderByDescending(e=>(string)e.Element(a+"published")).Select(e=>new{id=(string)e.Element(yt+"videoId"),title=(string)e.Element(a+"title"),published=(string)e.Element(a+"published")}).Take(15).ToArray();
 }
 static IEnumerable<string> DivBlocks(string html,string className){foreach(Match first in Regex.Matches(html,@"<div\b(?=[^>]*\bclass=[""'][^""']*\b"+Regex.Escape(className)+@"\b[^""']*[""'])[^>]*>",RegexOptions.IgnoreCase)){int start=first.Index+first.Length,depth=1;foreach(Match tag in Regex.Matches(html.Substring(start),@"</?div\b[^>]*>",RegexOptions.IgnoreCase)){depth+=tag.Value.StartsWith("</")?-1:1;if(depth==0){yield return html.Substring(start,tag.Index);break;}}}}
 static string ThumbField(string block,string label){foreach(Match m in Regex.Matches(block,@"<dt\b[^>]*>(.*?)</dt>\s*<dd\b[^>]*>(.*?)</dd>",RegexOptions.Singleline|RegexOptions.IgnoreCase))if(Clean(m.Groups[1].Value)==label)return ShortText(Clean(m.Groups[2].Value),350);return "";}
 static string CultureField(string html,params string[] labels){foreach(string label in labels){string value=ThumbField(html,label);if(value!="")return value;}return "";}
 static object CultureDetail(string id){if(!Regex.IsMatch(id,@"^\d{1,12}$"))throw new Exception("잘못된 행사 번호");string html=Fetch("https://www.culture.go.kr/portal/cltInfo/oneCltInfo/oneCltInfoView.do?menuNo=200010&pblprfrSn="+id);string intro=string.Join(" ",new[]{"view-contents","view-content","editor-content","cont-editor"}.SelectMany(c=>DivBlocks(html,c)).Select(Clean).Where(v=>v!=""));if(intro=="")intro=CultureField(html,"행사소개","공연소개","소개","내용");return new{venue=CultureField(html,"장소","공연장명"),address=CultureField(html,"주소"),eventTime=CultureField(html,"공연시간","행사시간","시간"),duration=CultureField(html,"소요시간"),audience=CultureField(html,"관람연령","관람등급","대상","관람대상"),organizer=CultureField(html,"주최/주관","주최·주관","주관","주최"),contact=CultureField(html,"문의","문의처"),price=CultureField(html,"가격","요금","관람료"),introduction=ShortText(intro,1000)};}

 static object Culture(string requestedTargets,string requestedRegion){var wanted=requestedTargets.Split(new[]{','},StringSplitOptions.RemoveEmptyEntries);int inspected=0;string regionFilter=(requestedRegion??"").Trim();string url="https://www.culture.go.kr/portal/cltInfo/oneCltInfo/list.do?menuNo=200010"+(regionFilter==""?"":"&ctpvNm="+Uri.EscapeDataString(regionFilter));var pages=Enumerable.Range(1,12).AsParallel().AsOrdered().WithDegreeOfParallelism(4).Select(page=>Fetch(url+"&pageIndex="+page)).ToArray();var items=new List<object>();var seen=new HashSet<string>();
  foreach(string block in pages.SelectMany(html=>DivBlocks(html,"box-thumb"))){
   string source=WebUtility.HtmlDecode(Regex.Match(block,@"<a\b(?=[^>]*\bclass=[""'][^""']*\bbtn-link\b[^""']*[""'])[^>]*\bhref=[""']([^""']+)",RegexOptions.Singleline|RegexOptions.IgnoreCase).Groups[1].Value);
   if(source=="")source=WebUtility.HtmlDecode(Regex.Match(block,@"<a\b[^>]*\bhref=[""']([^""']+)",RegexOptions.Singleline|RegexOptions.IgnoreCase).Groups[1].Value);string poster=WebUtility.HtmlDecode(Regex.Match(block,@"<img\b[^>]*\bsrc=[""']([^""']+)",RegexOptions.Singleline|RegexOptions.IgnoreCase).Groups[1].Value);
   string title=Clean(Regex.Match(block,@"<span\b[^>]*\bclass=[""'][^""']*\btit\b[^""']*[""'][^>]*>(.*?)</span>",RegexOptions.Singleline|RegexOptions.IgnoreCase).Groups[1].Value);
   var tags=Regex.Matches(block,@"<ul\b[^>]*\bclass=[""'][^""']*\bthumb-tag\b[^""']*[""'][^>]*>(.*?)</ul>",RegexOptions.Singleline|RegexOptions.IgnoreCase).Cast<Match>().SelectMany(x=>Regex.Matches(x.Groups[1].Value,@"<span\b[^>]*\bclass=[""'][^""']*\btxt\b[^""']*[""'][^>]*>(.*?)</span>",RegexOptions.Singleline|RegexOptions.IgnoreCase).Cast<Match>()).Select(x=>Clean(x.Groups[1].Value)).Where(x=>x!="").ToArray();
   if(title==""||poster=="")continue;if(source=="")source=url;source=new Uri(new Uri("https://www.culture.go.kr"),source).ToString();if(!seen.Add(poster))continue;string itemRegion=tags.LastOrDefault()??regionFilter;if(regionFilter!=""&&itemRegion!=regionFilter)continue;string[] targets=new string[0];if(wanted.Length>0){if(++inspected>24)break;try{string detail=Clean(Fetch(source));string age=Regex.Match(detail,@"(?:관람연령|관람대상|이용대상|참여대상).{0,180}").Value;targets=DetectTargets(age);if(!targets.Intersect(wanted).Any())continue;}catch{continue;}}string cultureId=Regex.Match(block,@"name=[""']subSeq[""']\s+value=[""'](\d+)").Groups[1].Value;items.Add(new{cultureId=cultureId,category=tags.FirstOrDefault()??"",organizer=ThumbField(block,"주관"),contact=ThumbField(block,"문의"),title=title,poster=new Uri(new Uri("https://www.culture.go.kr"),poster).ToString(),source=source,dates=ThumbField(block,"기간"),region=itemRegion,price=tags.FirstOrDefault(t=>t=="무료"||t=="유료")??"",targets=targets});if(items.Count>=144)break;
  }return items;
 }
 static string[] DetectTargets(string text){var targets=new HashSet<string>();if(Regex.IsMatch(text,@"초등|초[·ㆍ/,\s]*중"))targets.Add("elementary");if(Regex.IsMatch(text,@"중학생|중학교|중등|초[·ㆍ/,\s]*중|중[·ㆍ/,\s]*고"))targets.Add("middle");if(Regex.IsMatch(text,@"고등|중[·ㆍ/,\s]*고"))targets.Add("high");if(text.Contains("청소년"))targets.Add("youth");if(Regex.IsMatch(text,@"전체\s*관람|전.?연령|연령\s*제한\s*없")||(targets.Count==0&&text.Contains("누구나"))){targets.UnionWith(new[]{"elementary","middle","high","youth"});}var age=Regex.Match(text,@"(?:만\s*)?(\d{1,2})\s*세\s*이상");if(age.Success&&targets.Count==0){int n=int.Parse(age.Groups[1].Value);if(n<=12)targets.Add("elementary");if(n<=15)targets.Add("middle");if(n<=18)targets.Add("high");if(n<=24)targets.Add("youth");}return targets.ToArray();}
 static string DetectRegion(string text){if(Regex.IsMatch(text,@"전국|지역\s*제한\s*없"))return "전국";var regions=new[]{"서울","부산","대구","인천","광주","대전","울산","세종","경기","강원","충북","충남","전북","전남","경북","경남","제주"};return string.Join(",",regions.Where(r=>text.Contains(r)));}
 static string ContentDiv(string html){var first=Regex.Match(html,@"<div\b[^>]*\bid=[""']viewContents[""'][^>]*>",RegexOptions.IgnoreCase);if(!first.Success)return "";int depth=1;foreach(Match tag in Regex.Matches(html.Substring(first.Index+first.Length),@"</?div\b[^>]*>",RegexOptions.IgnoreCase)){depth+=tag.Value.StartsWith("</")?-1:1;if(depth==0)return html.Substring(first.Index+first.Length,tag.Index);}return html.Substring(first.Index+first.Length);}
 static string ShortText(string value,int max){value=Regex.Replace(value??"",@"\s+"," ").Trim();return value.Length>max?value.Substring(0,max-1)+"…":value;}
 static string InfoField(string html,string label){var match=Regex.Match(html,@"<span\b[^>]*class=[""']tit[""'][^>]*>\s*"+Regex.Escape(label)+@"\s*</span>(.*?)</li>",RegexOptions.Singleline|RegexOptions.IgnoreCase);return match.Success?ShortText(Clean(match.Groups[1].Value),180):"";}
 static string BodyLines(string body){return WebUtility.HtmlDecode(Regex.Replace(Regex.Replace(body,@"<(?:br\b[^>]*|/(?:div|p|li|h[1-6]|tr))>","\n",RegexOptions.IgnoreCase),"<[^>]+>"," ")).Replace("\u200b","");}
 static string Section(string lines,string labels){var all=lines.Split('\n');for(int i=0;i<all.Length;i++){string line=all[i].Trim();line=Regex.Replace(line,@"^[■●○◆▶□\s]+","");var heading=Regex.Match(line,@"^(?:"+labels+@")\s*[:：]?\s*(.*)$");if(!heading.Success)continue;var parts=new List<string>();if(heading.Groups[1].Value.Trim()!="")parts.Add(heading.Groups[1].Value.Trim());for(int j=i+1;j<all.Length&&parts.Count<4;j++){string next=all[j].Trim();if(next=="")continue;if(Regex.IsMatch(next,@"^[■●○◆▶□]"))break;parts.Add(Regex.Replace(next,@"^[-·•\s]+",""));}return ShortText(string.Join(" / ",parts),230);}return "";}
 static string ContestState(){lock(gate){if(!collecting&&DateTime.UtcNow-contestsAt>TimeSpan.FromHours(1)){collecting=true;System.Threading.ThreadPool.QueueUserWorkItem(_=>CollectContests());}return json.Serialize(new{loading=collecting,items=contests,error=contestError,checkedAt=contestsAt==DateTime.MinValue?"":contestsAt.ToString("o")});}}
 static void CollectContests(){var fresh=new List<object>();try{
  var ids=new HashSet<int>();for(int page=1;page<=2;page++){string list=Fetch("https://www.wevity.com/?c=find&s=1&gub=2&cidx=30&gbn=list&gp="+page);foreach(Match m in Regex.Matches(list,@"(?:&amp;|&)ix=(\d+)"))ids.Add(int.Parse(m.Groups[1].Value));}
  int checkedCount=0;var today=DateTime.UtcNow.AddHours(9).Date;
  foreach(int id in ids.OrderByDescending(x=>x).Take(45)){
   if(fresh.Count>=25)break;checkedCount++;try{
    string source="https://www.wevity.com/?c=find&s=1&gub=2&gbn=view&ix="+id,html=Fetch(source);
    string title=Clean(Regex.Match(html,"<h6[^>]*class=[\"']tit[\"'][^>]*>(.*?)</h6>",RegexOptions.Singleline).Groups[1].Value);
    string period=Regex.Match(html,"<input[^>]*name=[\"']during[\"'][^>]*>",RegexOptions.IgnoreCase).Value;
    if(period=="")period=Regex.Match(html,"<input[^>]*value=[\"'][^\"']*\\d{4}-\\d{2}-\\d{2}[^\"']*[\"'][^>]*name=[\"']during[\"'][^>]*>").Value;
    var dates=Regex.Matches(period,@"\d{4}-\d{2}-\d{2}");if(dates.Count<2)continue;DateTime start,end;if(!DateTime.TryParse(dates[0].Value,out start)||!DateTime.TryParse(dates[1].Value,out end)||start.Date>today||end.Date<today)continue;
    if(!Regex.IsMatch(title,"공모|경진|대회|콘테스트|백일장|경연|슬로건")||Regex.IsMatch(title,"서포터즈|기자단|체험단|수강생"))continue;
    string body=ContentDiv(html);
    string text=Clean(body),lines=BodyLines(body);var eligibility=Section(lines,@"(?:지원|응모|참가|참여|신청|모집|공모)\s*(?:자격|대상)");if(eligibility=="")eligibility=InfoField(html,"지원자격");
    var targets=DetectTargets(eligibility);if(targets.Length==0)continue;
    string poster=WebUtility.HtmlDecode(Regex.Match(body,"(?:src|data-src)=[\"']((?:https://www.wevity.com)?/upload/contest/[^\"']+)[\"']").Groups[1].Value);if(poster=="")poster=WebUtility.HtmlDecode(Regex.Match(html,"(?:src|data-src)=[\"']((?:https://www.wevity.com)?/upload/contest/[^\"']+)[\"']").Groups[1].Value);if(poster=="")continue;
    fresh.Add(new{title=title,poster=new Uri(new Uri("https://www.wevity.com"),poster).ToString(),source=source,dates=dates[0].Value+" ~ "+dates[1].Value,region=DetectRegion(eligibility+" "+title),price="",endsOn=dates[1].Value,targets=targets,eligibility=eligibility,organizer=InfoField(html,"주최/주관"),category=InfoField(html,"분야"),topic=Section(lines,@"(?:공모|응모|모집)\s*(?:주제|내용|분야)"),submission=Section(lines,@"(?:접수|응모|제출|참가|신청)\s*방법"),awards=Section(lines,@"(?:공모전\s*)?(?:시상\s*내역|시상\s*규모|상금)") ,contact=Section(lines,@"문의(?:\s*(?:사항|처))?"),fee=Section(lines,@"(?:참가비|응모료|접수비)")});
   }catch{}System.Threading.Thread.Sleep(200);
  }if(ids.Count==0)throw new Exception("공모전 목록 형식이 변경되었거나 연결에 실패했습니다.");
  lock(gate){contests=fresh;contestError="";contestsAt=DateTime.UtcNow;}
 }catch{lock(gate){contestError="공모전 연결 실패. 잠시 후 다시 확인하세요.";contestsAt=DateTime.UtcNow.AddMinutes(-55);}}finally{lock(gate){collecting=false;}}}
}
