using System;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Security.Cryptography;
using System.Reflection;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

// Invoke the actual SchoolClockPlus EXE collectors without starting its UI.
class PortraitCollector {
 static readonly object Gate=new object();
 static readonly JavaScriptSerializer Json=new JavaScriptSerializer{MaxJsonLength=16000000};
 static string Root;
 static Assembly SourceAssembly;
 static Dictionary<string,object> Snapshot=new Dictionary<string,object>();
 static int Failures;
 static object Source(string type,string method,params object[] args) {
  return SourceAssembly.GetType(type,true).GetMethod(method,BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic).Invoke(null,args);
 }
 static string Media(string method,params object[] args) {return Convert.ToString(Source("MediaSources",method,args));}
 static bool Sejong(string value) {return Regex.IsMatch(value??"",@"세종(?!대(?:학교|학|왕))");}
 static string Text(Dictionary<string,object> item,string key) { object value;return item.TryGetValue(key,out value)&&value!=null?Convert.ToString(value):""; }
 static List<Dictionary<string,object>> Rows(object value) { return Json.Deserialize<List<Dictionary<string,object>>>(Json.Serialize(value))??new List<Dictionary<string,object>>(); }
 static string Today {get{return DateTime.UtcNow.AddHours(9).ToString("yyyy-MM-dd");}}
 static bool Current(Dictionary<string,object> item) {
  string end=Text(item,"endsOn");
  if(end==""){var dates=Regex.Matches(Text(item,"dates"),@"20\d{2}[.\-/]\d{1,2}[.\-/]\d{1,2}");if(dates.Count>0){DateTime parsed;if(DateTime.TryParse(dates[dates.Count-1].Value.Replace('.','-').Replace('/','-'),out parsed))end=parsed.ToString("yyyy-MM-dd");}}
  if(end!="")item["endsOn"]=end;
  return end==""||string.CompareOrdinal(end,Today)>=0;
 }
 static void Save(string kind,List<Dictionary<string,object>> rows) {
  rows=rows.Where(Current).GroupBy(x=>Regex.Replace(Text(x,"title"),@"^\[세종\]\s*","")).Select(g=>g.First()).Take(12).ToList();
  foreach(var item in rows) {
   string remote=Text(item,kind=="books"||kind=="movies"?"image":"poster");
   if(remote.StartsWith("http://"))remote="https://"+remote.Substring(7);
   Uri uri;
   if(Uri.TryCreate(remote,UriKind.Absolute,out uri)&&uri.Scheme=="https") {
    string hash;using(var sha=SHA256.Create())hash=BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(remote+"-win10-v2"))).Replace("-","").Substring(0,24).ToLowerInvariant();
    string relative="portrait-did-images/"+hash+".jpg",path=Path.Combine(Root,relative.Replace('/',Path.DirectorySeparatorChar));
    try {
     if(!File.Exists(path)){var request=(HttpWebRequest)WebRequest.Create(uri);request.Timeout=15000;request.ReadWriteTimeout=15000;request.UserAgent="Mozilla/5.0 SchoolClockPlus";using(var response=request.GetResponse())using(var input=response.GetResponseStream())using(var buffer=new MemoryStream()){byte[] chunk=new byte[16384];int count;while((count=input.Read(chunk,0,chunk.Length))>0){buffer.Write(chunk,0,count);if(buffer.Length>12000000)throw new IOException("Poster too large");}if(buffer.Length<100)throw new IOException("Empty poster");buffer.Position=0;using(var original=Image.FromStream(buffer)){double scale=Math.Min(1,Math.Min(1016.0/original.Width,858.0/original.Height));using(var resized=new Bitmap(Math.Max(1,(int)(original.Width*scale)),Math.Max(1,(int)(original.Height*scale)))){using(var graphics=Graphics.FromImage(resized)){graphics.Clear(Color.White);graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;graphics.DrawImage(original,0,0,resized.Width,resized.Height);}var encoder=ImageCodecInfo.GetImageEncoders().First(x=>x.MimeType=="image/jpeg");using(var quality=new EncoderParameters(1)){quality.Param[0]=new EncoderParameter(System.Drawing.Imaging.Encoder.Quality,85L);resized.Save(path,encoder,quality);}}}}}
     item["image"]=relative;
    } catch {item["image"]=remote;}
   }
   item["kind"]=kind;
   if(kind=="contests"||kind=="exhibitions")item["url"]=Text(item,"source");
  }
  lock(Gate) {
   Snapshot[kind]=rows;
   Snapshot[kind+"UpdatedAt"]=DateTime.UtcNow.ToString("o");
   Snapshot["savedAt"]=(long)(DateTime.UtcNow-new DateTime(1970,1,1)).TotalMilliseconds;
   string encoded=Json.Serialize(Snapshot).Replace("<","\\u003c");
   Atomic("portrait-did-data.json",encoded+"\n");
   Atomic("portrait-did-feed.js","window.DODAM_PORTRAIT_DATA="+encoded+";\n");
   // Embed the data as well, so opening the HTML immediately shows content.
   string html=Path.Combine(Root,"dodam-clock-discover.html");
   if(File.Exists(html)) {string source=File.ReadAllText(html);source=Regex.Replace(source,@"window\.DODAM_PORTRAIT_SEED=[^\r\n]*;",m=>"window.DODAM_PORTRAIT_SEED="+encoded+";");Atomic("dodam-clock-discover.html",source);}
  }
  Console.WriteLine(kind+": "+rows.Count+" items");
 }
 static void Atomic(string name,string text) {string path=Path.Combine(Root,name),temp=path+".tmp";File.WriteAllText(temp,text,new UTF8Encoding(false));if(File.Exists(path))File.Replace(temp,path,null);else File.Move(temp,path);}
 static void Contests() {
  var until=DateTime.UtcNow.AddMinutes(12);
  while(DateTime.UtcNow<until) {
   var result=Json.Deserialize<Dictionary<string,object>>(Media("Get","/api/poster-contests",""));
   if(!(bool)result["loading"]) {
    var rows=Rows(result["items"]);
    if(rows.Count==0&&!string.IsNullOrWhiteSpace(Convert.ToString(result["error"])))throw new Exception("Contests unavailable");
    Save("contests",rows.Where(x=>{
     string targets=Json.Serialize(x.ContainsKey("targets")?x["targets"]:null),eligibility=Text(x,"eligibility");
     bool middle=targets.Contains("middle"),youth=targets.Contains("youth");
     if(!middle&&Regex.IsMatch(eligibility,@"후기\s*청소년|(?:19|20)\s*[~∼-]\s*24|대학(?:생|원생)"))return false;
     return middle||youth;
    }).ToList());return;
   }
   Thread.Sleep(1000);
  }
  throw new TimeoutException("Contests collection timeout");
 }
 static void Exhibitions() {
  var rows=new List<Dictionary<string,object>>();
  var candidates=Rows(Json.DeserializeObject(Media("Get","/api/culture","?region="+Uri.EscapeDataString("세종"))));
  rows.AddRange(candidates.Where(x=>Text(x,"region")=="세종").Where(Current));
  rows=rows.GroupBy(x=>Regex.Replace(Text(x,"title"),@"^\[세종\]\s*","")).Select(g=>g.First()).Take(12).ToList();
  foreach(var item in rows) {
   string id=Text(item,"cultureId");if(!Regex.IsMatch(id,@"^\d{1,12}$"))continue;
   try {
    var details=Json.Deserialize<Dictionary<string,object>>(Media("Get","/api/culture-detail","?id="+Uri.EscapeDataString(id)));
    foreach(string field in new[]{"venue","address","eventTime","duration","audience","organizer","contact","price","introduction"})if(!string.IsNullOrWhiteSpace(Text(details,field)))item[field]=details[field];
   }catch{}
   if(string.IsNullOrWhiteSpace(Text(item,"introduction"))) {
    try {
     string html=Media("Fetch",Text(item,"source"));
     foreach(string cls in new[]{"performance-detail-alt","show-view__info__in-1","view-contents","view-content","view_con"}) {
      var blocks=(IEnumerable<string>)Source("MediaSources","DivBlocks",html,cls);
      foreach(string block in blocks)foreach(Match paragraph in Regex.Matches(block,@"<p\b[^>]*>(.*?)</p>",RegexOptions.Singleline|RegexOptions.IgnoreCase)) {
       string line=Regex.Replace(Media("Clean",paragraph.Groups[1].Value),@"\s+"," ").Trim();
       if(line.Length>=55&&Regex.IsMatch(line,@"(?:다|요)[.!?。]")&&!Regex.IsMatch(line,"예매|할인|취소|환불|주차|공지|유의|쿠키|개인정보|러닝타임|관람연령|패키지|티켓|회원")){item["introduction"]=line;break;}
      }
      if(!string.IsNullOrWhiteSpace(Text(item,"introduction")))break;
     }
    }catch{}
   }
   // Where the source only supplies an image, use a short factual genre
   // description, keeping venue/time/fees in their own fields.
   string intro=Text(item,"introduction"),title=Text(item,"title"),genre=Text(item,"category");
   if(intro=="") {
    if(title.Contains("재즈"))intro="재즈 오케스트라의 연주를 세종에서 만나는 음악 공연입니다.";
    else if(title.Contains("내한공연"))intro="해외 연주자들의 음악을 세종에서 만나는 내한공연입니다.";
    else if(title.Contains("꿈의 오케스트라"))intro="꿈의 오케스트라 ‘세종’이 선보이는 정기연주회입니다.";
    else if(genre.Contains("뮤지컬"))intro="음악과 이야기를 함께 만나는 뮤지컬 공연입니다.";
    else if(genre.Contains("연극"))intro="배우들의 연기로 이야기를 만나는 연극 공연입니다.";
    else if(genre.Contains("전시"))intro="작품을 직접 감상하며 주제와 작가의 시선을 만나는 전시입니다.";
    else intro="세종에서 열리는 음악 공연입니다.";
   }
   if(title.Contains("드보르자크")&&intro.Contains("브람스")&&intro.Contains("슈만"))intro="브람스·슈만·드보르자크의 작품을 함께 만나는 클래식 연주회입니다.";
   else if(title.Contains("베토벤")&&title.Contains("교향곡 9"))intro="베토벤 교향곡 9번 ‘합창’을 선보이는 국립심포니콘서트오케스트라 공연입니다.";
   item["shortIntroduction"]=intro.Length>80?intro.Substring(0,79)+"…":intro;
   item.Remove("introduction");
  }
  Save("exhibitions",rows);
 }
 static void Books() {
  Source("BookSources","Refresh");
  var result=Json.Deserialize<Dictionary<string,object>>(Convert.ToString(Source("BookSources","Get")));var rows=Rows(result["items"]);if(rows.Count==0)throw new Exception("Books unavailable");Save("books",rows);
 }
 static void Movies() {
  Source("MovieSources","Refresh");
  var result=Json.Deserialize<Dictionary<string,object>>(Convert.ToString(Source("MovieSources","Get")));var rows=Rows(result["items"]);if(rows.Count==0)throw new Exception("Movies unavailable");foreach(var row in rows){row["url"]="https://www.kobis.or.kr/";row["boxOfficeDate"]=Convert.ToString(result["date"]);}
  Save("movies",rows);
 }
 static void Job(string name,Action action) {try{action();}catch(Exception error){Interlocked.Increment(ref Failures);Console.WriteLine(name+": previous data preserved ("+error.GetType().Name+")");}}
 static int Main(string[] args) {
  Root=args.Length>0?Path.GetFullPath(args[0]):AppDomain.CurrentDomain.BaseDirectory;
  string sourceExe=args.Length>1?args[1]:Path.GetFullPath(Path.Combine(Root,"..","SchoolClockPlus","SchoolClock-Setup.exe"));
  if(!File.Exists(sourceExe))sourceExe=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"SchoolClock-Setup.exe");
  SourceAssembly=Assembly.Load(File.ReadAllBytes(sourceExe));
  Directory.CreateDirectory(Path.Combine(Root,"portrait-did-images"));
  ServicePointManager.SecurityProtocol=SecurityProtocolType.Tls12;
  try{Snapshot=Json.Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(Root,"portrait-did-data.json")));}catch{}
  // Cultural events remain strictly within Sejong. Contests are age-filtered.
  foreach(string kind in new[]{"exhibitions"})if(Snapshot.ContainsKey(kind))Snapshot[kind]=Rows(Snapshot[kind]).Where(x=>Text(x,"region")=="세종"&&Current(x)).ToList();
  Snapshot["scope"]="sejong-culture-v3";
  if(args.Length>2&&args[2]=="culture-only") {Job("exhibitions",Exhibitions);return Failures==0?0:1;}
  // Limit concurrent network/CPU work on older DID PCs.
  Job("exhibitions",Exhibitions);Job("contests",Contests);Job("books",Books);Job("movies",Movies);
  return Failures==0?0:1;
 }
}
