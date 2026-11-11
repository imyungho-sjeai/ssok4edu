"""Refresh Sejong education news; keep previous files on download failure."""
import argparse
import datetime as dt
import email.utils
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

URL = 'https://news.google.com/rss/search?' + urllib.parse.urlencode({'q':'세종교육청 when:7d','hl':'ko','gl':'KR','ceid':'KR:ko'})

def refresh(folder):
    try:
        with urllib.request.urlopen(urllib.request.Request(URL, headers={'User-Agent':'DodamDID/1.0'}), timeout=25) as response:
            body = response.read(2 * 1024 * 1024 + 1)
    except Exception:
        if os.name != 'nt':
            raise
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / 'news.xml'
            command = "Invoke-WebRequest -UseBasicParsing -TimeoutSec 25 -Uri '" + URL.replace("'", "''") + "' -OutFile '" + str(target).replace("'", "''") + "'"
            subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-Command',command], check=True, timeout=35, capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
            body = target.read_bytes()
    if len(body) > 2 * 1024 * 1024 or b'<!DOCTYPE' in body.upper() or b'<!ENTITY' in body.upper():
        raise ValueError('Unexpected RSS data')
    root = ET.fromstring(body)
    if root.tag != 'rss':
        raise ValueError('Expected RSS')
    rows, seen = [], set()
    now = dt.datetime.now(dt.timezone.utc)
    for item in root.findall('./channel/item'):
        title = re.sub(r'\s+', ' ', item.findtext('title','')).strip()
        url = item.findtext('link','').strip()
        try:
            published = email.utils.parsedate_to_datetime(item.findtext('pubDate','')).astimezone(dt.timezone.utc)
        except (ValueError, TypeError, AttributeError):
            continue
        if not title or title in seen or not url.startswith('https://') or not now-dt.timedelta(days=7) <= published <= now+dt.timedelta(minutes=5):
            continue
        seen.add(title)
        publisher = item.findtext('source','').strip()
        if publisher and title.endswith(' - '+publisher):
            title = title[:-len(' - '+publisher)]
        rows.append({'title':title[:500],'url':url,'source':publisher[:100],'date':published.astimezone(dt.timezone(dt.timedelta(hours=9))).strftime('%Y-%m-%d'),'publishedUtc':published.isoformat()})
    rows.sort(key=lambda row:row['publishedUtc'], reverse=True)
    if not rows:
        raise ValueError('No recent articles; previous news preserved')
    payload = {'savedAt':int(time.time()*1000),'keyword':'세종교육청','items':rows[:40]}
    encoded = json.dumps(payload,ensure_ascii=True).replace('<','\\u003c')
    outputs = [('dodam-news.json',encoded+'\n'),('dodam-news-feed.js','window.DODAM_NEWS_RESPONSE='+encoded+';\n')]
    # HTML files stay untouched; open displays reload these feeds each hour.
    for name, value in outputs:
        path = folder/name
        temporary = path.with_suffix(path.suffix+'.news.tmp')
        temporary.write_text(value,encoding='utf-8')
        temporary.replace(path)
    print('Updated',len(payload['items']),'Sejong education news articles')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--folder',type=Path,default=Path(__file__).resolve().parent)
    refresh(parser.parse_args().folder)
