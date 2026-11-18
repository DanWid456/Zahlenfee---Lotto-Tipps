#!/usr/bin/env python3
"""Ergänzt assets/data/*.json um neue Ziehungen.

Standardquelle: lottochaos.com Open Data (CC BY 4.0).
Mit --allow-noncommercial zusätzlich daowa89/lottery-archive (nur private,
nicht-kommerzielle Nutzung!) – aktueller, aber nicht für eine veröffentlichte App.

Es werden nur Ziehungen angehängt, die neuer sind als die letzte vorhandene,
und nur, wenn sie die Spielregeln erfüllen. Bestehende Daten bleiben unverändert.
"""
import argparse, csv, io, json, sys, urllib.request, datetime as dt
from pathlib import Path

LC = 'https://raw.githubusercontent.com/Loisirio/lottochaos-lottery-data/main/data/{}.csv'
DW = 'https://raw.githubusercontent.com/daowa89/lottery-archive/main/{}/results.csv'

# code: (Hauptzahlen, max, Zusatzzahlen, Zusatz-min, Zusatz-max, Ziehtage Mo=0)
RULES = {
    'CH': (6, 42, 1, 1, 6, {2, 5}),
    'DE': (6, 49, 1, 0, 9, {2, 5}),   # Superzahl
    'AT': (6, 45, 1, 1, 45, {2, 4, 6}),  # Zusatzzahl; vereinzelt Freitagsziehungen
    'EM': (5, 50, 2, 1, 12, {1, 4}),
    'EJ': (5, 50, 2, 1, 12, {1, 4}),
}

def lottochaos(code):
    name = {'CH': 'ch_lotto', 'DE': 'lotto', 'AT': 'at_lotto', 'EM': 'em', 'EJ': 'ej'}[code]
    k, _, ne, *_ = RULES[code]
    for r in csv.DictReader(io.StringIO(fetch(LC.format(name)))):
        yield (r['date'], r.get('flag') or '', [int(r[f'n{i}']) for i in range(1, k + 1)],
               [int(r[f'b{i}']) for i in range(1, ne + 1) if r.get(f'b{i}')])

def daowa(code):
    path = {'DE': 'de/lotto_6aus49', 'AT': 'at/lotto_6aus45', 'EM': 'eu/euromillions'}.get(code)
    if not path:
        return
    k = RULES[code][0]
    for r in csv.DictReader(io.StringIO(fetch(DW.format(path)))):
        extra = [r[c] for c in ('superzahl', 'zusatzzahl', 's1', 's2') if r.get(c)]
        yield (r['date'], '', [int(r[f'n{i}']) for i in range(1, k + 1)], [int(x) for x in extra])

def fetch(url):
    with urllib.request.urlopen(url, timeout=30) as f:
        return f.read().decode('utf-8')

def valid(code, date, main, extras):
    k, mx, ne, emin, emax, days = RULES[code]
    return (len(main) == k and len(set(main)) == k and all(1 <= n <= mx for n in main)
            and len(extras) == ne and all(emin <= e <= emax for e in extras)
            and dt.date.fromisoformat(date).weekday() in days)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', default='assets/data')
    ap.add_argument('--allow-noncommercial', action='store_true')
    a = ap.parse_args()
    changed = 0
    for code in RULES:
        p = Path(a.data) / f'{code}.json'
        doc = json.loads(p.read_text())
        last = max(d[0] for d in doc['draws'])
        new = {}
        sources = [lottochaos] + ([daowa] if a.allow_noncommercial else [])
        for src in sources:
            try:
                for date, label, m, e in src(code):
                    if date > last and (date, label) not in new:
                        if valid(code, date, m, e):
                            new[(date, label)] = [date, label, sorted(m), sorted(e) if code in ('EM', 'EJ') else e]
                        else:
                            print(f'{code} {date}: ungültig, übersprungen {m} {e}', file=sys.stderr)
            except Exception as ex:  # Quelle nicht erreichbar -> nächste Quelle
                print(f'{code}: {src.__name__} fehlgeschlagen: {ex}', file=sys.stderr)
        if new:
            doc['draws'] += sorted(new.values())
            doc['updated'] = dt.date.today().isoformat()
            p.write_text(json.dumps(doc, separators=(',', ':')))
            changed += len(new)
        print(f'{code}: {len(new)} neu (bisher bis {last})')
    print(f'Total neu: {changed}')

if __name__ == '__main__':
    main()
