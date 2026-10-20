"""Collect up to 10 newest open contests whose eligibility includes middle school students."""
import argparse
from datetime import datetime, timedelta, timezone, date
import hashlib
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser
import io
import json
from pathlib import Path
import re
import time
import urllib.parse
import urllib.request
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent
WEVITY = 'https://www.wevity.com/'
WEVITY_LIST = WEVITY + '?c=find&s=1&gub=2&cidx=30&gbn=list&gp='
SEJONG_LIST = WEVITY + '?c=find&s=1&gub=2&sp=contents&sw=%EC%84%B8%EC%A2%85&gbn=list&gp='
KST = timezone(timedelta(hours=9))
VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'}
BLOCK = {'div', 'p', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'br', 'tr'}


class Node:
    def __init__(self, tag='', attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []
        self.parent = None

    def find(self, tag=None, cls=None, id=None):
        for child in self.children:
            if isinstance(child, Node):
                if (tag is None or child.tag == tag) and (cls is None or cls in child.attrs.get('class', '').split()) and (id is None or child.attrs.get('id') == id):
                    yield child
                yield from child.find(tag, cls, id)

    def text(self):
        if self.tag in ('script', 'style'):
            return ''
        return ('\n' if self.tag in BLOCK else '') + ''.join(c.text() if isinstance(c, Node) else c for c in self.children) + ('\n' if self.tag in BLOCK else '')


class Tree(HTMLParser):
    def __init__(self, html):
        super().__init__(convert_charrefs=True)
        self.root = Node()
        self.stack = [self.root]
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        child = Node(tag, attrs)
        child.parent = self.stack[-1]
        self.stack[-1].children.append(child)
        if tag not in VOID:
            self.stack.append(child)

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, 0, -1):
            if self.stack[index].tag == tag:
                del self.stack[index:]
                break

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def compact(text):
    return ' '.join(text.replace('\ufeff', '').replace('\u200b', '').split())


def prepare_poster(body):
    """Keep native resolution, including smaller originals. Never upscale."""
    with Image.open(io.BytesIO(body)) as opened:
        if opened.width * opened.height > 40000000 or opened.width > 40000 or opened.height > 40000:
            raise ValueError('Poster is too large to decode')
        image = ImageOps.exif_transpose(opened)
        width, height = image.size
        opened.load()
        if opened.format in ('JPEG', 'PNG', 'GIF') and opened.getexif().get(274, 1) == 1:
            return body, {'JPEG':'jpg','PNG':'png','GIF':'gif'}[opened.format], width, height
        output = io.BytesIO()
        image.convert('RGBA').save(output, 'PNG')
        return output.getvalue(), 'png', width, height


def download(url, limit=4 * 1024 * 1024):
    url = network_url(url)
    request = urllib.request.Request(url, headers={'User-Agent': 'DodamSchoolDisplay/1.0', 'Cache-Control': 'no-cache'})
    with urllib.request.urlopen(request, timeout=25) as response:
        network_url(response.geturl())
        data = response.read(limit + 1)
    if len(data) > limit:
        raise ValueError('Contest response exceeds size limit')
    return data


def network_url(url):
    parts = urllib.parse.urlsplit(url)
    if parts.scheme != 'https' or parts.hostname not in ('www.wevity.com', 'wevity.com') or parts.username or parts.password or parts.port not in (None, 443):
        raise ValueError('Unexpected collector URL')
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, urllib.parse.quote(parts.path, safe='/%:@!$&\'()*+,;=-._~'), urllib.parse.quote(parts.query, safe='=&%[]:+,;/@?'), ''))


def wevity_listing(html):
    container = next(Tree(html).root.find('ul', cls='list'), None)
    if container is None:
        raise ValueError('Wevity list structure changed')
    found = {}
    for link in container.find('a'):
        url = urllib.parse.urljoin(WEVITY, link.attrs.get('href', ''))
        query = urllib.parse.parse_qs(urllib.parse.urlsplit(url).query)
        ix = query.get('ix', [''])[0]
        if query.get('gbn', [''])[0] not in ('view', 'viewok') or not ix.isdigit():
            continue
        row = link.parent
        while row is not None and row is not container and row.tag != 'li':
            row = row.parent
        status = next(row.find(cls='dday'), None) if row is not None and row.tag == 'li' else None
        if status is not None and compact(status.text()) not in ('접수중', '마감임박'):
            continue
        found[int(ix)] = network_url(WEVITY + '?c=find&s=1&gub=2&gbn=view&ix=' + ix)
    return found


def middle_school_target(value):
    # Youth-targeted announcements include middle-school pupils unless explicit restrictions exclude them.
    return bool(re.search(r'중학생|중학교|중등|청소년|초[·ㆍ․・/,\s]*중|중[·ㆍ․・/,\s]*고', value))


def sejong_related(value):
    if re.search(r'세종시|세종특별자치시|세종\s*(?:지역|시민|교육청|시립)', value):
        return True
    if re.search(r'세종(?:사이버)?대|세종학당|세종문화회관|세종대왕', value):
        return False
    return '세종' in value


def wevity_detail(html, url, today):
    container = next(Tree(html).root.find(cls='contest-detail'), None)
    if container is None:
        raise ValueError('Wevity detail structure changed')
    title_node = next(container.find('h6', cls='tit'), None)
    content = next(container.find(id='viewContents'), None)
    if title_node is None or content is None:
        raise ValueError('Missing contest title/content')
    title = compact(title_node.text())
    fields = {el.attrs.get('name'): el.attrs.get('value', '') for el in container.find('input')}
    dates = re.search(r'(\d{4}-\d{2}-\d{2})\s*~\s*(\d{4}-\d{2}-\d{2})', fields.get('during', ''))
    if dates is None:
        raise ValueError('Missing contest period')
    starts, ends = date.fromisoformat(dates[1]), date.fromisoformat(dates[2])
    if not starts <= today <= ends:
        return None
    if not re.search(r'공모|경진|대회|콘테스트|백일장|경연|슬로건', title) or re.search(r'서포터즈|기자단|체험단|수강생', title):
        return None
    allowed = eligibility(content.text())
    if not allowed or not middle_school_allowed(allowed):
        return None
    regional = compact(' '.join([title, allowed, fields.get('agent', '')]))
    sejong = sejong_related(regional)
    targeted = middle_school_target(allowed)
    if not targeted and not sejong:
        return None
    posters = []
    thumb = next(container.find(cls='thumb'), Node())
    for image in list(thumb.find('img')) + list(content.find('img')):
        value = urllib.parse.urljoin(WEVITY, image.attrs.get('src', ''))
        parts = urllib.parse.urlsplit(value)
        if parts.hostname in ('www.wevity.com', 'wevity.com') and parts.path.startswith('/upload/contest/'):
            value = network_url(value)
            if value not in posters:
                posters.append(value)
    if not posters:
        return None
    ix = urllib.parse.parse_qs(urllib.parse.urlsplit(url).query)['ix'][0]
    return {'id': int(ix), 'title': title, 'source': url, 'middleSchoolTarget': targeted, 'sejongRelated': sejong,
            'startsOn': starts.isoformat(), 'endsOn': ends.isoformat(), 'eligibility': allowed,
            'posterCandidates': posters[:3], 'attribution': '위비티'}


QUAL = re.compile(r'(?:지원|응모|참가|참여|신청|모집)\s*(?:자격|대상)|공모\s*대상')
HEADER = re.compile(r'^[■□●○▶◆◇※]|^(?:\d+[.)]\s*)?(?:공모\s*(?:주제|내용|분야|부문)|접수|모집\s*기간|응모\s*방법|지원\s*방법|참가\s*방법|시상|문의|대회\s*일정)')


def eligibility(body):
    lines = [compact(line) for line in body.splitlines() if compact(line)]
    result = []
    for i, line in enumerate(lines):
        if not QUAL.search(line):
            continue
        result.append(line)
        for following in lines[i + 1:i + 13]:
            if HEADER.search(following) or QUAL.search(following):
                break
            result.append(following)
    if not result:
        # A heading-free announcement is accepted only with an explicit nationwide invitation.
        result = [line for line in lines if re.search(r'전국.{0,25}(?:중학생|중학교|중[·ㆍ․・/\s]*고|초[·ㆍ․・/\s]*중|청소년|누구나)', line)]
    return compact(' '.join(result))[:2500]


def middle_school_allowed(value):
    if not value:
        return False
    value = re.sub(r'\s+', ' ', value)
    # Do not treat the youth category, a prize category or a body mention as eligibility.
    if re.search(r'중(?:학생|학교).{0,10}(?:불가|제외|불가능)|(?:고등학생|고등학교\s*재학생|대학생|대학원생|성인|일반인)\s*(?:만|한정)|(?:만\s*)?(?:1[7-9]|[2-9]\d)\s*세\s*이상', value):
        return False
    # Local-residency qualifications cannot be assumed to include Dodam pupils in Sejong.
    if not re.search(r'전국|지역\s*제한\s*없|거주지\s*제한\s*없', value) and re.search(r'(?:거주|소재|관내|시민|도민|구민)', value) and '세종' not in value:
        return False
    if re.search(r'중학생|중학교|중등|초[·ㆍ․・/,\s]*중|중[·ㆍ․・/,\s]*고', value):
        return True
    # Youth alone may conceal a high-school-only competition.
    if re.search(r'(?:고등학생|고등학교|대학생|대학원생|초등학생|초등학교)', value):
        return False
    if re.search(r'누구나|제한\s*없|모든\s*(?:국민|연령)|전\s*국민|대한민국\s*국민|청소년', value):
        return True
    ages = re.search(r'(\d{1,2})\s*[~∼–-]\s*(\d{1,2})\s*세', value)
    return bool(ages and int(ages[1]) <= 13 and int(ages[2]) >= 15)


def publish(directory, manifest):
    def atomic(path, body):
        temp = path.with_name(path.name + '.tmp')
        temp.write_text(body, encoding='utf-8')
        temp.replace(path)
    encoded = json.dumps(manifest, ensure_ascii=True).replace('<', '\\u003c')
    atomic(directory / 'low-gongmo.json', json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    atomic(directory / 'low-gongmo-feed.js', 'window.DODAM_GONGMO_RESPONSE=' + encoded + ';\n')
    atomic(directory / 'low-gongmo-remote.js', 'window.DODAM_GONGMO_REMOTE_RESPONSE=' + encoded + ';\n')
    page = directory / 'low-gongmo.html'
    if page.exists():
        source = page.read_text(encoding='utf-8')
        updated, count = re.subn(r'window\.DODAM_GONGMO_SEED=[^\r\n]*;\r?\n', lambda m: 'window.DODAM_GONGMO_SEED=' + encoded + ';\n', source)
        if count == 1:
            atomic(page, updated)


def refresh(directory=ROOT, today=None, fetch=download, max_pages=6):
    directory, today = Path(directory), today or datetime.now(KST).date()
    candidates, images, used, scanned, titles = {}, [], set(), set(), set()
    assets = directory / 'low-gongmo-images'
    assets.mkdir(exist_ok=True)
    # Sort the discovered registration IDs rather than trusting promoted positions.
    sources = [(WEVITY_LIST, page) for page in range(1, max_pages + 1)] + [(SEJONG_LIST, page) for page in range(1, min(3, max_pages) + 1)]
    for source, page in sources:
        discovered = wevity_listing(fetch(source + str(page)).decode('utf-8-sig'))
        candidates.update(discovered)

    def inspect(entry):
        ix, url = entry
        try:
            item = wevity_detail(fetch(url).decode('utf-8-sig'), url, today)
            return ix, item, None
        except Exception as error:
            return ix, None, type(error).__name__
        finally:
            if fetch is download:
                time.sleep(0.25)

    qualified = []
    # Four bounded workers shorten collection without making the DID fetch these pages.
    with ThreadPoolExecutor(max_workers=4) as pool:
        for ix, item, failure in pool.map(inspect, sorted(candidates.items(), reverse=True)):
            if failure:
                print('Contest skipped:', ix, failure, flush=True)
                continue
            scanned.add(ix)
            if item is not None:
                qualified.append(item)

    rejected_posters = 0
    for item in sorted(qualified, key=lambda value: value['id'], reverse=True):
        ix, best = item['id'], None
        title_key = re.sub(r'[^0-9a-z가-힣]', '', item['title'].lower())
        if title_key in titles:
            continue
        posters = item.pop('posterCandidates')
        for poster in posters:
            try:
                body, ext, width, height = prepare_poster(fetch(poster, 30 * 1024 * 1024))
                if best is None or width * height > best[3] * best[4]:
                    best = (poster, body, ext, width, height)
            except Exception as error:
                print('Poster skipped:', ix, type(error).__name__, flush=True)
        if best is None:
            rejected_posters += 1
            continue
        poster, body, ext, width, height = best
        fingerprint = hashlib.sha256(body).hexdigest()[:24]
        if fingerprint in used:
            continue
        used.add(fingerprint)
        titles.add(title_key)
        path = assets / (fingerprint + '.' + ext)
        if not path.exists():
            path.write_bytes(body)
        path.touch()
        images.append(dict(item, src='low-gongmo-images/' + path.name, width=width, height=height, poster=poster, resolutionVerified=True, nativeSize=True, upscaled=False))
        print('Collected:', ix, item['endsOn'], flush=True)
        if len(images) >= 10:
            break
    if not candidates or not scanned or len(scanned) < len(candidates) * 0.7:
        raise ValueError('Source missing or too many failed details; previous snapshot preserved')
    images = sorted(images, key=lambda item: item['id'], reverse=True)[:10]
    manifest = {'version': 1, 'checkedAt': int(time.time() * 1000), 'source': WEVITY_LIST + '1',
                'selection': 'Wevity only; newest posting IDs; open dates; middle-school OR youth target OR Sejong-related and middle-school eligible; native poster resolution including small originals; never upscale',
                'checkedContests': len(scanned), 'eligibleContests': len(qualified), 'posterUnavailable': rejected_posters,
                'images': images}
    # File mtimes reset at GitHub checkout. Persist last-use times in the manifest instead.
    previous = {}
    try:
        previous = json.loads((directory / 'low-gongmo.json').read_text(encoding='utf-8'))
    except (OSError, ValueError):
        pass
    seen_at = previous.get('assetSeenAt', {})
    if not isinstance(seen_at, dict):
        seen_at = {}
    stamp = manifest['checkedAt']
    previous_images = previous.get('images', [])
    if not isinstance(previous_images, list):
        previous_images = []
    for item in previous_images + images:
        if not isinstance(item, dict):
            continue
        name = Path(item.get('src', '')).name
        if re.fullmatch(r'[a-f0-9]{24}\.(?:png|jpg|gif)', name):
            seen_at[name] = stamp
    active = {Path(item['src']).name for item in images}
    for old in assets.iterdir():
        if not re.fullmatch(r'[a-f0-9]{24}\.(?:png|jpg|gif)', old.name):
            continue
        last_use = seen_at.setdefault(old.name, stamp)
        if not isinstance(last_use, (int, float)):
            seen_at[old.name] = stamp
            last_use = stamp
        if old.name not in active and last_use < stamp - 86400000:
            old.unlink()
            seen_at.pop(old.name, None)
    present = {p.name for p in assets.iterdir() if p.is_file()}
    manifest['assetSeenAt'] = {name: value for name, value in seen_at.items() if name in present}
    publish(directory, manifest)
    print('Updated low-gongmo:', len(images), 'posters from', len(scanned), 'checked contests.', flush=True)
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=ROOT)
    refresh(parser.parse_args().directory)
