"""Einmalig: erzeugt assets/data/*.json aus lotto.db (+ Lotto Österreich)."""
import csv, json, sqlite3, sys, datetime as dt
db, at_lc, at_extra, out = sys.argv[1:5]
con = sqlite3.connect(db)
def dump(code, draws):
    draws.sort(key=lambda d: (d[0], d[1]))
    json.dump({'code': code, 'updated': dt.date.today().isoformat(), 'draws': draws},
              open(f'{out}/{code}.json', 'w'), separators=(',', ':'))
    print(code, len(draws), draws[0][0], draws[-1][0])
for code in ('CH', 'DE', 'EM', 'EJ'):
    rows = []
    for d, lab, *n, z1, z2 in con.execute(
            "SELECT datum,label,n1,n2,n3,n4,n5,n6,z1,z2 FROM ziehung WHERE lotterie=?", (code,)):
        rows.append([d, lab, [x for x in n if x is not None], [x for x in (z1, z2) if x is not None]])
    dump(code, rows)
at = {}
for r in csv.DictReader(open(at_lc)):
    at[r['date']] = [r['date'], '', sorted(int(r[f'n{i}']) for i in range(1, 7)), [int(r['b1'])]]
last = max(at)
for r in csv.DictReader(open(at_extra)):
    if r['date'] > last:
        at[r['date']] = [r['date'], '', sorted(int(r[f'n{i}']) for i in range(1, 7)), [int(r['zusatzzahl'])]]
dump('AT', list(at.values()))
