using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Threading;
using System.Web;
using System.Web.Script.Serialization;
static class BookSources {
 const string Root="https://www.mcst.go.kr";
 const string ListUrl=Root+"/site/s_culture/book/bookList.jsp";
 static readonly object Gate=new object();static volatile string cached="";static string checkedCycle="";static DateTime retryAt=DateTime.MinValue;static int refreshing;static Timer timer;
 static string CachePath {get{return Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"book-recommendations-cache.json");}}
 internal static string Cycle(DateTime utc){var korea=utc.AddHours(9);return (korea.Hour<9?korea.Date.AddDays(-1):korea.Date).ToString("yyyy-MM-dd");}
 internal static bool IsDue(DateTime utc,string successfulCycle,DateTime retry){return successfulCycle!=Cycle(utc)&&utc>=retry;}
 public static void Start(){lock(Gate){if(timer!=null)return;try{var saved=new JavaScriptSerializer{MaxJsonLength=4000000}.Deserialize<Dictionary<string,object>>(File.ReadAllText(CachePath));string data=(string)saved["data"];var parsed=new JavaScriptSerializer{MaxJsonLength=4000000}.Deserialize<Dictionary<string,object>>(data);if(parsed.ContainsKey("items")){cached=data;checkedCycle=(string)saved["cycle"];}}catch{}timer=new Timer(_=>{try{Get();}catch{}},null,2000,30000);}}
 static string Text(string value){return Regex.Replace(HttpUtility.HtmlDecode(Regex.Replace(value??"",@"<[^>]*>"," ")),@"\s+"," ").Trim();}
 static string Match(string text,string pattern){return Regex.Match(text,pattern,RegexOptions.Singleline|RegexOptions.IgnoreCase).Groups[1].Value;}
 static string Fetch(string url){var request=(HttpWebRequest)WebRequest.Create(url);request.Timeout=12000;request.ReadWriteTimeout=12000;request.UserAgent="SchoolClockPlus/1.0";using(var response=request.GetResponse())using(var reader=new StreamReader(response.GetResponseStream(),Encoding.UTF8))return reader.ReadToEnd();}
 internal static List<Dictionary<string,object>> ParseList(string html){
  var result=new List<Dictionary<string,object>>();var seen=new HashSet<string>();
  foreach(Match match in Regex.Matches(html,@"<a\b[^>]*href=""bookView\.jsp\?pDetailSeq=(\d+)""[^>]*>(.*?)</a>",RegexOptions.Singleline|RegexOptions.IgnoreCase)){
   string id=match.Groups[1].Value,body=match.Groups[2].Value;if(!seen.Add(id))continue;
   string title=Text(Match(body,@"<p\b[^>]*class=""sub-tit""[^>]*>(.*?)</p>"));if(title=="")continue;
   string image=HttpUtility.HtmlDecode(Match(body,@"<img\b[^>]*src=""([^""]+)"""));Uri imageUri;if(!Uri.TryCreate(new Uri(Root),image,out imageUri)||imageUri.Host!="www.mcst.go.kr")image="";else image=imageUri.AbsoluteUri;
   result.Add(new Dictionary<string,object>{{"id",id},{"title",title},{"author",Text(Match(body,@"<strong>저/역자</strong>\s*:\s*(.*?)</li>"))},{"publisher",Text(Match(body,@"<strong>출판사</strong>\s*:\s*(.*?)</li>"))},{"description",""},{"image",image},{"url",Root+"/site/s_culture/book/bookView.jsp?pDetailSeq="+id}});
  }return result;
 }
 internal static string ParseDescription(string html){string block=Match(html,@"<div\b[^>]*class=""view_con""[^>]*>(.*?)<div\b[^>]*class=""goportal""");if(block=="")return "";block=Regex.Replace(block,@"<h3\b[^>]*>.*?</h3>","",RegexOptions.Singleline);var paragraphs=Regex.Matches(block,@"<p\b[^>]*>(.*?)</p>",RegexOptions.Singleline|RegexOptions.IgnoreCase).Cast<Match>().Select(m=>Text(m.Groups[1].Value)).Where(t=>t!="").ToList();string text=paragraphs.Count>0?string.Join("\n\n",paragraphs):Text(block);if(text.StartsWith("사서의 추천 글"))text=text.Substring("사서의 추천 글".Length).Trim();int end=text.IndexOf("저자 소개",StringComparison.Ordinal);if(end>0)text=text.Substring(0,end).Trim();return text;}
 static void Refresh(){if(Interlocked.CompareExchange(ref refreshing,1,0)!=0)return;try{lock(Gate){if(!IsDue(StandardClock.UtcNow,checkedCycle,retryAt))return;}
  string html=Fetch(ListUrl);var items=ParseList(html);if(items.Count==0)throw new Exception("문체부 추천 도서 목록을 읽지 못했습니다.");
  var tasks=items.Select(item=>Task.Run(()=>{item["description"]=ParseDescription(Fetch((string)item["url"]));if(((string)item["description"]).Length==0)throw new Exception("소개 정보 누락");})).ToArray();Task.WaitAll(tasks);
  string year=Match(html,@"var downYear = ""(\d+)"""),month=Match(html,@"var downMonth = ""(\d+)""");
  var json=new JavaScriptSerializer{MaxJsonLength=4000000};string data=json.Serialize(new{items=items,error="",recommended=year+"-"+month,updatedAt=StandardClock.UtcNow.ToString("o"),source="문화체육관광부 추천도서"});lock(Gate){cached=data;checkedCycle=Cycle(StandardClock.UtcNow);retryAt=DateTime.MinValue;try{string temp=CachePath+".tmp";File.WriteAllText(temp,json.Serialize(new{cycle=checkedCycle,data=data}),new UTF8Encoding(false));if(File.Exists(CachePath))File.Replace(temp,CachePath,null);else File.Move(temp,CachePath);}catch{}}
 }catch{lock(Gate){retryAt=StandardClock.UtcNow.AddMinutes(10);}}finally{Interlocked.Exchange(ref refreshing,0);}}
 public static string Get(){Start();bool due;lock(Gate){due=IsDue(StandardClock.UtcNow,checkedCycle,retryAt);}if(due){if(cached=="")Refresh();else ThreadPool.QueueUserWorkItem(_=>Refresh());}if(cached!="")return cached;return new JavaScriptSerializer().Serialize(new{items=new object[0],error="문화체육관광부 추천 도서를 불러오지 못했습니다. 10분 후 다시 확인합니다."});}
}
