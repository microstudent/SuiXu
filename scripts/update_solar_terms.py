#!/usr/bin/env python3
"""Refresh factual solar-term dates from HKO's published 1901–2100 tables.
Explicit maintenance only; never run by the app or the build.
Writes atomically only after every year passes validation.
"""
import concurrent.futures
import datetime
import json
import pathlib
import re
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
NAMES = "小寒 大寒 立春 雨水 惊蛰 春分 清明 谷雨 立夏 小满 芒种 夏至 小暑 大暑 立秋 处暑 白露 秋分 寒露 霜降 立冬 小雪 大雪 冬至".split()
TRANSLATE = str.maketrans("驚蟄穀滿芒種處", "惊蛰谷满芒种处")

def fetch(year):
    url = f"https://www.hko.gov.hk/tc/gts/time/calendar/text/files/T{year}c.txt"
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                source = response.read().decode("utf-8-sig")
            result = {}
            for line in source.splitlines():
                match = re.match(r"(\d+)年(\d+)月(\d+)日\s+\S+\s+星期\S+\s+(\S+)", line)
                if match:
                    y, m, d, name = match.groups()
                    name = name.translate(TRANSLATE)
                    if name in NAMES:
                        key = datetime.date(int(y), int(m), int(d)).isoformat()
                        result[key] = name
            assert len(result) == 24, f"{year}: expected 24 terms, got {len(result)}"
            assert set(result.values()) == set(NAMES)
            return result
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2 * (attempt + 1))

if __name__ == "__main__":
    terms = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for i, data in enumerate(pool.map(fetch, range(1901, 2101))):
            terms.update(data)
            if (i + 1) % 25 == 0:
                print(f"Validated {i + 1}/200 years", flush=True)
    target = ROOT / "Sources/SuixuCore/Resources/solar-terms.json"
    temp = target.with_suffix(".tmp")
    temp.write_text(json.dumps(terms, ensure_ascii=False, sort_keys=True, indent=2) + "\n")
    temp.replace(target)
    print(f"Saved {len(terms)} solar terms", flush=True)
