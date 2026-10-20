"""Discover the CURRENT top popup list on the school homepage; no fixed image list."""
import argparse
import hashlib
from html.parser import HTMLParser
import io
import json
from pathlib import Path
import re
import time
import urllib.parse
import urllib.request
from PIL import Image, ImageOps

HOME = 'https://dodam.sjedums.kr/dodam-m/main.do?sso=ok'
VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'}


def image_url(value):
    url = urllib.parse.urljoin(HOME, value.strip())
    parts = urllib.parse.urlsplit(url)
    if parts.scheme != 'https' or parts.hostname != 'dodam.sjedums.kr' or parts.username or parts.password or parts.port not in (None, 443):
        raise ValueError('Unexpected popup image origin')
    if not parts.path.startswith('/upload/'):
        raise ValueError('Unexpected popup image path')
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, parts.path, parts.query, ''))


class TopPopupParser(HTMLParser):
    """Only #allPopupList belongs to the requested top popup carousel."""
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.root = None
        self.found = False
        self.closed = False
        self.table = False
        self.items = []
        self.seen = set()
        self.row_title = []
        self.in_title = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('id') == 'allPopupList':
            self.root = len(self.stack)
            self.found = True
        active = self.root is not None
        if active:
            if tag == 'table':
                self.table = True
            if tag == 'tr':
                self.row_title = []
            if tag == 'td' and 'tit' in attrs.get('class', '').split():
                self.in_title = True
            value = attrs.get('data-image') if tag == 'a' else None
            if value:
                url = image_url(value)
                if url not in self.seen:
                    self.seen.add(url)
                    title = ' '.join(' '.join(self.row_title).split()) or attrs.get('title') or attrs.get('data-alt', '')
                    self.items.append({'source': url, 'title': ' '.join(title.split())[:500]})
        if tag not in VOID:
            self.stack.append(tag)

    def handle_data(self, data):
        if self.root is not None and self.in_title:
            self.row_title.append(data)

    def handle_endtag(self, tag):
        if tag == 'td':
            self.in_title = False
        if tag in self.stack:
            index = len(self.stack) - 1 - self.stack[::-1].index(tag)
            del self.stack[index:]
            if self.root is not None and len(self.stack) <= self.root:
                self.root = None
                self.closed = True


def discover(source):
    parser = TopPopupParser()
    parser.feed(source.decode('utf-8-sig'))
    if not parser.found or not parser.closed or not parser.table:
        raise ValueError('Top popup list is missing or incomplete; previous list preserved')
    # An intact, empty top list means all popups were removed. Publish [] intentionally.
    return parser.items


def download(url, limit):
    request = urllib.request.Request(url, headers={'User-Agent': 'DodamLowDisplay/1.0', 'Cache-Control': 'no-cache'})
    with urllib.request.urlopen(request, timeout=25) as response:
        final = urllib.parse.urlsplit(response.geturl())
        if final.scheme != 'https' or final.hostname != 'dodam.sjedums.kr':
            raise ValueError('Unexpected redirect')
        body = response.read(limit + 1)
    if len(body) > limit:
        raise ValueError('School response exceeded size limit')
    return body


def prepare_image(body):
    with Image.open(io.BytesIO(body)) as opened:
        if opened.width * opened.height > 40000000:
            raise ValueError('Popup image is too large to decode safely')
        opened.load()
        if opened.format == 'GIF' and getattr(opened, 'is_animated', False):
            return body, 'gif', opened.width, opened.height
        image = ImageOps.exif_transpose(opened)
        fmt = opened.format
        unchanged = image.size == opened.size and max(opened.getexif().get(274, 1), 1) == 1
        if unchanged and fmt in ('PNG', 'JPEG', 'GIF') and image.width <= 1080 and image.height <= 1500:
            return body, {'PNG': 'png', 'JPEG': 'jpg', 'GIF': 'gif'}[fmt], image.width, image.height
        image.thumbnail((1080, 1500), Image.Resampling.LANCZOS)  # never enlarges small images
        target = io.BytesIO()
        extension = 'jpg' if fmt == 'JPEG' else 'png'
        if extension == 'jpg':
            image.convert('RGB').save(target, 'JPEG', quality=92)
        else:
            image.convert('RGBA').save(target, 'PNG')
        return target.getvalue(), extension, image.width, image.height


def patch_seed(html_file, manifest):
    if not html_file.exists():
        return
    source = html_file.read_text(encoding='utf-8')
    seed = json.dumps(manifest, ensure_ascii=True).replace('<', '\\u003c')
    updated, count = re.subn(r'window\.DODAM_LOW_SEED=[^\r\n]*;\r?\n', lambda match: 'window.DODAM_LOW_SEED=' + seed + ';\n', source)
    if count == 1:
        html_file.write_text(updated, encoding='utf-8')


def refresh(directory):
    directory = Path(directory)
    items = discover(download(HOME, 4 * 1024 * 1024))
    images, hashes = [], set()
    assets = directory / 'low-display-images'
    assets.mkdir(exist_ok=True)
    for item in items:
        body, ext, width, height = prepare_image(download(item['source'], 30 * 1024 * 1024))
        fingerprint = hashlib.sha256(body).hexdigest()[:24]
        filename = fingerprint + '.' + ext
        if fingerprint in hashes:
            continue
        hashes.add(fingerprint)
        destination = assets / filename
        if not destination.exists():
            destination.write_bytes(body)
        images.append(dict(item, src='low-display-images/' + filename, width=width, height=height))
    manifest = {'version': 1, 'checkedAt': int(time.time() * 1000), 'source': HOME, 'images': images}
    # Publish only after every current image succeeded. Failure preserves the previous complete list.
    temporary = directory / 'low-display.json.tmp'
    temporary.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(directory / 'low-display.json')
    feed = 'window.DODAM_LOW_RESPONSE=' + json.dumps(manifest, ensure_ascii=True).replace('<', '\\u003c') + ';\n'
    (directory / 'low-display-feed.js').write_text(feed, encoding='utf-8')
    (directory / 'low-display-remote.js').write_text(feed.replace('window.DODAM_LOW_RESPONSE=', 'window.DODAM_LOW_REMOTE_RESPONSE=', 1), encoding='utf-8')
    patch_seed(directory / 'low-display.html', manifest)
    print('Discovered', len(items), 'current top popups;', len(images), 'unique display images.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parent)
    refresh(parser.parse_args().directory)
