#!/usr/bin/env python3
"""Holt die Jackpots der nächsten Ziehungen und schreibt assets/data/jackpot.json.

Quellen (Stand 11/2026, alle öffentlich von den Lotterie-Websites selbst geladen):
- Swisslos: Gewinnzahlen-Seiten, Zeile "Jackpot nächste Ziehung: CHF 45'800'000"
- Österreichische Lotterien: https://www.lotterien.at/api/jackpot/all (JSON)
- LOTTO.de: /api/stats/entities.<spiel>/last -> "jackpotNew" (Mio. €)

Fällt eine Quelle aus, bleibt der bisherige Eintrag mit seinem alten Zeitstempel
stehen; die App blendet Einträge aus, die älter als 4 Tage sind.
"""
import argparse
import datetime as dt
import html
import json
import re
import sys
import urllib.request
from pathlib import Path

UA = {'User-Agent': 'Mozilla/5.0 (compatible; Zahlenfee-Jackpot/1.0)'}
SWISSLOS = {
    'CH': 'https://www.swisslos.ch/de/swisslotto/information/gewinnzahlen/gewinnzahlen-quoten.html',
    'EM': 'https://www.swisslos.ch/de/euromillions/information/gewinnzahlen/gewinnzahlen-quoten.html',
}
AT_API = 'https://www.lotterien.at/api/jackpot/all'
DE_API = 'https://www.lotto.de/api/stats/entities.{}/last'


def fetch(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as f:
        return f.read().decode('utf-8', 'replace')


# ---------- Parser (ohne Netzwerk, damit testbar)

def parse_swisslos(page):
    text = re.sub(r'<script[\s\S]*?</script>', ' ', page, flags=re.I)
    text = html.unescape(re.sub(r'<[^>]+>', ' ', text))
    text = re.sub(r'\s+', ' ', text)
    m = re.search(r"Jackpot nächste Ziehung:\s*CHF\s*(\d{1,3}(?:['’]\d{3})+|\d+)", text)
    return int(re.sub(r"['’]", '', m.group(1))) if m else None


def _at_amount(a):
    factor = {'BASE_CURRENCY': 1, 'BASE_CURRENCY_MILLIONS': 1_000_000}.get(a.get('weight'))
    return round(a['value'] * factor) if factor is not None and a.get('value') is not None else None


def parse_lotterien_at(data):
    """-> {'AT': (betrag, art), 'EM': (betrag, art)}; art = jackpot|guaranteed."""
    out = {}
    for key, code in (('lotto', 'AT'), ('euromillionen', 'EM')):
        p = (data.get(key) or {}).get('__original__', {}).get('announcedFirstRankPrize')
        if not p or p.get('status') != 'FINAL':
            continue
        amount = _at_amount(p.get('amount', {}))
        if not amount:
            continue
        # Lotto ohne laufenden Jackpot: angezeigt wird die garantierte Mindestsumme
        kind = 'guaranteed' if code == 'AT' and p.get('jackpotCounter', 0) == 0 else 'jackpot'
        out[code] = (amount, kind)
    return out


def parse_lotto_de(data):
    """jackpotNew ist in Mio. €; None, solange die Quoten noch fehlen."""
    if isinstance(data, list):
        data = data[0] if data else {}
    v = data.get('jackpotNew')
    return round(float(v) * 1_000_000) if v not in (None, 0) else None


# ---------- Ablauf

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='assets/data/jackpot.json')
    a = ap.parse_args()
    path = Path(a.out)
    old = {}
    if path.exists():
        for e in json.loads(path.read_text()).get('jackpots', []):
            old[(e['lottery'], e['country'])] = e
    now = dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    new = {}

    def put(lottery, country, amount, currency, kind='jackpot'):
        new[(lottery, country)] = {'lottery': lottery, 'country': country, 'amount': amount,
                                   'currency': currency, 'kind': kind, 'fetched': now}

    for code, url in SWISSLOS.items():
        try:
            v = parse_swisslos(fetch(url))
            if v:
                put(code, 'CH', v, 'CHF')
            else:
                print(f'Swisslos {code}: kein Betrag gefunden', file=sys.stderr)
        except Exception as ex:
            print(f'Swisslos {code}: {ex}', file=sys.stderr)
    try:
        for code, (v, kind) in parse_lotterien_at(json.loads(fetch(AT_API))).items():
            put(code, 'AT', v, 'EUR', kind)
    except Exception as ex:
        print(f'lotterien.at: {ex}', file=sys.stderr)
    for code, entity in (('DE', 'lotto'), ('EJ', 'eurojackpot')):
        try:
            v = parse_lotto_de(json.loads(fetch(DE_API.format(entity))))
            if v:
                put(code, 'DE', v, 'EUR')
            else:
                print(f'LOTTO.de {entity}: noch kein neuer Jackpot', file=sys.stderr)
        except Exception as ex:
            print(f'LOTTO.de {entity}: {ex}', file=sys.stderr)

    merged = {**old, **new}
    entries = sorted(merged.values(), key=lambda e: (e['lottery'], e['country']))
    if [ {k: v for k, v in e.items() if k != 'fetched'} for e in entries] == \
       [ {k: v for k, v in e.items() if k != 'fetched'} for e in sorted(old.values(), key=lambda e: (e['lottery'], e['country']))]:
        print('Jackpots unverändert')
        return
    path.write_text(json.dumps({'updated': now, 'jackpots': entries}, ensure_ascii=False, indent=1))
    for e in entries:
        print(f"{e['lottery']}/{e['country']}: {e['amount']:,} {e['currency']} ({e['kind']})")


if __name__ == '__main__':
    main()
