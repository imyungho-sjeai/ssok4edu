"""Fetch official school titles server-side so the DID needs only same-origin GET.

RSS is preferred. The official list page is a fallback for the current RSS error.
On any total failure the previous JSON file remains untouched.
"""
import argparse
import datetime
import email.utils
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import time
import urllib.request
import xml.etree.ElementTree as ET

RSS_URL = 'https://dodam.sjedums.kr/dodam-m/na/ntt/selectRssFeed.do?mi=8176&bbsId=4654'
LIST_URL = 'https://dodam.sjedums.kr/dodam-m/na/ntt/selectNttList.do?mi=8176&bbsId=4654'


def clean_title(value):
    return re.sub(r'\s+', ' ', re.sub(r'\[\s*가정통신문\s*\]', '', value)).strip()


def latest(rows):
    result, seen = [], set()
    # Real dates, rather than pinned position, decide which titles are newest.
    rows.sort(key=lambda row: (row.get('_date', ''), row.get('_id', 0)), reverse=True)
    for row in rows:
        title = clean_title(row['title'])
        if title and title not in seen:
            seen.add(title)
            date = row.get('_date', '')[:10]
            result.append({'title': title, 'date': date if re.fullmatch(r'20\d{2}-\d{2}-\d{2}', date) else ''})
        if len(result) == 4:
            break
    if not result:
        raise ValueError('No valid notice titles; preserving the previous snapshot')
    return result


def parse_rss(source):
    if b'<!DOCTYPE' in source.upper() or b'<!ENTITY' in source.upper():
        raise ValueError('Unexpected XML declarations')
    root = ET.fromstring(source)
    if root.tag != 'rss' or root.find('channel') is None:
        raise ValueError('The RSS endpoint did not return RSS XML')
    rows = []
    for index, item in enumerate(root.findall('./channel/item')):
        title = item.findtext('title', '').strip()
        if not title:
            continue
        published = item.findtext('pubDate', '')
        try:
            published = email.utils.parsedate_to_datetime(published).astimezone(datetime.timezone.utc).isoformat()
        except (ValueError, TypeError, AttributeError):
            published = ''
        rows.append({'title': title, '_date': published, '_id': -index})
    return latest(rows)


class NoticeListParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.rows = []
        self.row = None
        self.capture = False
        self.title_parts = []
        self.row_parts = []
        self.cell_parts = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'tr':
            self.row, self.title_parts, self.row_parts = {}, [], []
            self.cell_parts = None
        if self.row is not None and tag == 'td':
            self.cell_parts = []
        if self.row is not None and tag == 'a' and 'nttInfoBtn' in attrs.get('class', '').split():
            self.capture = True
            self.row['_id'] = int(attrs.get('data-id', '0'))

    def handle_data(self, data):
        if self.row is not None:
            self.row_parts.append(data)
            if self.cell_parts is not None:
                self.cell_parts.append(data)
            if self.capture:
                self.title_parts.append(data)

    def handle_endtag(self, tag):
        if tag == 'a':
            self.capture = False
        if tag == 'td' and self.row is not None and self.cell_parts is not None:
            date = re.fullmatch(r'\s*(20\d{2})[.\-/](\d{2})[.\-/](\d{2})\s*', ''.join(self.cell_parts))
            if date:
                self.row['_date'] = '-'.join(date.groups())
            self.cell_parts = None
        if tag == 'tr' and self.row is not None:
            if self.title_parts:
                self.row['title'] = ''.join(self.title_parts)
                if self.row.get('_date'):
                    self.rows.append(self.row)
            self.row = None


def parse_list(source):
    parser = NoticeListParser()
    parser.feed(source.decode('utf-8-sig'))
    return latest(parser.rows)


def download(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'DodamClockNoticeReader/1.0'})
    with urllib.request.urlopen(request, timeout=25) as response:
        source = response.read(2 * 1024 * 1024 + 1)
    if len(source) > 2 * 1024 * 1024:
        raise ValueError('School response exceeded the size limit')
    return source


def refresh(output):
    try:
        items, source = parse_rss(download(RSS_URL)), 'rss'
    except Exception as error:
        print('RSS unavailable; checking the official list:', type(error).__name__)
        items, source = parse_list(download(LIST_URL)), 'school-list'
    payload = {'savedAt': int(time.time() * 1000), 'source': source, 'items': items}
    output = Path(output)
    temporary = output.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(output)
    data_script = 'window.DODAM_NOTICE_RESPONSE=' + json.dumps(payload, ensure_ascii=True).replace('<', '\\u003c') + ';\n'
    output.with_name('dodam-notices-feed.js').write_text(data_script, encoding='utf-8')
    # Keep the single HTML's initial snapshot current too; no extra script file is needed.
    for filename in ['dodam-clock.html', 'dodam-clock-smt-v2.html']:
        display = output.with_name(filename)
        if display.exists():
            source_html = display.read_text(encoding='utf-8')
            seed = json.dumps(payload, ensure_ascii=True).replace('<', '\\u003c')
            updated, count = re.subn(r'window\.DODAM_NOTICE_SEED=[^\r\n]*;\r?\n', lambda match: 'window.DODAM_NOTICE_SEED=' + seed + ';\n', source_html)
            if count == 1:
                display.write_text(updated, encoding='utf-8')
    print('Updated', len(items), 'official titles via', source)


if __name__ == '__main__':
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument('--output', type=Path, default=Path(__file__).with_name('dodam-notices.json'))
    refresh(args.parse_args().output)
