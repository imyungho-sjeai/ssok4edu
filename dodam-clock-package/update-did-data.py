"""Refresh portable DID data on a PC with working HTTPS. Does not edit the original clock."""
import json
from pathlib import Path
import re
import time
import urllib.parse
import urllib.request
import importlib.util
import subprocess
import tempfile
import os

ROOT = Path(__file__).resolve().parent


def save(kind, payload):
    encoded = json.dumps(payload, ensure_ascii=True).replace('<', '\\u003c')
    stem = 'dodam-' + kind
    response = 'DODAM_' + ('NOTICE' if kind == 'notices' else 'WEATHER')
    for filename, content in [
        (stem + '.json', encoded + '\n'),
        (stem + '-feed.js', 'window.' + response + '_RESPONSE=' + encoded + ';\n'),
    ]:
        path = ROOT / filename
        temporary = path.with_suffix(path.suffix + '.tmp')
        temporary.write_text(content, encoding='utf-8')
        temporary.replace(path)
    html = ROOT / 'dodam-clock-did.html'
    source = html.read_text(encoding='utf-8')
    source, count = re.subn(
        r'window\.' + response + r'_SEED=[^\r\n]*;',
        lambda match: 'window.' + response + '_SEED=' + encoded + ';', source)
    if count != 1:
        raise ValueError('Expected exactly one HTML data seed: ' + response)
    html.write_text(source, encoding='utf-8')


def weather():
    params = dict(latitude='36.4800', longitude='127.2890',
                  current='temperature_2m,relative_humidity_2m,apparent_temperature,weather_code',
                  hourly='temperature_2m,weather_code,precipitation_probability',
                  daily='temperature_2m_max,temperature_2m_min',
                  timezone='Asia/Seoul', past_days=1, forecast_days=2)
    url = 'https://api.open-meteo.com/v1/forecast?' + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=25) as response:
        data = json.load(response)
    if not isinstance(data.get('current', {}).get('temperature_2m'), (int, float)):
        raise ValueError('Invalid weather response')
    if not isinstance(data.get('hourly', {}).get('time'), list):
        raise ValueError('Missing hourly forecasts')
    save('weather', dict(savedAt=int(time.time() * 1000), data=data))


def notices():
    spec = importlib.util.spec_from_file_location('dodam_notice_updater', ROOT / 'update-notices.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    def download(url):
        try:
            return module.download(url)
        except urllib.error.URLError:
            if os.name != 'nt':
                raise
            # Windows can build the school's certificate chain using its own store.
            # Keep certificate validation enabled in both download paths.
            with tempfile.TemporaryDirectory() as folder:
                target = Path(folder) / 'school.html'
                command = "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -TimeoutSec 25 -Uri '" + url.replace("'", "''") + "' -OutFile '" + str(target).replace("'", "''") + "'"
                subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', command],
                               check=True, timeout=35, capture_output=True,
                               creationflags=subprocess.CREATE_NO_WINDOW)
                return target.read_bytes()
    try:
        items = module.parse_rss(download(module.RSS_URL))
    except Exception:
        items = module.parse_list(download(module.LIST_URL))
    save('notices', dict(savedAt=int(time.time() * 1000), source='official-school', items=items))


if __name__ == '__main__':
    failed = False
    for name, refresh in [('Weather', weather), ('Notices', notices)]:
        try:
            refresh()
            print(name + ': updated')
        except Exception as error:
            failed = True
            print(name + ': failed; previous data preserved (' + type(error).__name__ + ')')
    raise SystemExit(1 if failed else 0)
