#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["fastembed>=0.3", "numpy", "socksio"]   # socksio: у тебя all_proxy=socks5://… (xraybox)
# ///
"""kb_sem — поиск по смыслу для kb.

Запускается из kb:  kb -s "запрос"   (сам kb вызывает:  uv run --script kb_sem.py ...)

Что делает:
  1. берёт тексты из кэша kb (PDF/DOCX/ODT, уже превращённые в текст) и обычные .md/.txt/.tex;
  2. режет их на куски по ~450 символов (модель читает ~128 токенов);
  3. каждый кусок превращает в вектор (модель эмбеддингов, работает на CPU, офлайн после загрузки);
  4. вектор запроса сравнивает с векторами кусков (косинус) и показывает ближайшие.
Пересчитываются только изменившиеся файлы.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import zlib
from pathlib import Path

import numpy as np

SKIP_DIRS = {".git", "node_modules", "__pycache__", "build", "dist", ".venv", "venv", "_templates"}
TEXT_EXT = {".md", ".txt", ".tex"}
CHUNK_CHARS = 450          # paraphrase-multilingual-MiniLM читает ~128 токенов ≈ 350-450 символов
MIN_CHARS = 20
DEFAULT_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
PER_FILE_LIMIT = 3         # не больше стольких кусков из одного файла в выдаче
REPORT_NAME = re.compile(r"отч[её]т|report", re.IGNORECASE)
LAB_NAME = re.compile(r"lab|лаб|лаборатор", re.IGNORECASE)


# ----------------------------------------------------------------- эмбеддинги
class HashEmbedder:
    """Отладочная замена модели (KB_EMBEDDER=hash): мешок слов по хешам, без смысла.
    Нужна только чтобы проверять индексацию/поиск без загрузки нейросети."""
    dim = 256

    def __call__(self, texts):
        out = np.zeros((len(texts), self.dim), dtype=np.float32)
        for i, t in enumerate(texts):
            for w in "".join(c if c.isalnum() else " " for c in t.lower()).split():
                out[i, zlib.crc32(w[:5].encode()) % self.dim] += 1.0
        return _normalize(out)


def _normalize(a):
    return a / (np.linalg.norm(a, axis=1, keepdims=True) + 1e-9)


def get_embedder(model_name):
    if os.environ.get("KB_EMBEDDER") == "hash":
        return HashEmbedder()
    from fastembed import TextEmbedding   # импорт здесь: быстрый запуск, если модель не нужна
    print(f"🧠 загружаю модель {model_name} (при первом запуске скачается)…", file=sys.stderr)
    model = TextEmbedding(model_name=model_name)

    def embed(texts):
        return _normalize(np.array(list(model.embed(list(texts))), dtype=np.float32))
    return embed


# ----------------------------------------------------------------- источники и куски
def is_report(path: str) -> bool:
    """Отчёты по лабам не добавляем в смысловой индекс."""
    return bool(REPORT_NAME.search(Path(path).name))


def is_lab_material(path: str) -> bool:
    """Материалы из каталогов LABS и файлы по лабораторным не индексируем."""
    p = Path(path)
    return any(part.casefold().startswith("labs") for part in p.parts) or bool(LAB_NAME.search(p.name))


def iter_sources(cache: Path, roots):
    """Даёт (src_path, kind_of_source, text). kind_of_source: pdf | docx | odt | text"""
    tdir = cache / "text"
    if tdir.is_dir():
        for f in sorted(tdir.glob("*.txt")):
            raw = f.read_text(encoding="utf-8", errors="ignore")
            first, _, _ = raw.partition("\n")
            if not first.startswith("#SRC\t"):
                continue
            src = first.split("\t", 1)[1].strip()
            if is_report(src) or is_lab_material(src):
                continue
            ext = Path(src).suffix.lower().lstrip(".")
            yield src, ("pdf" if ext == "pdf" else "docx" if ext == "docx" else "odt"), raw
    for root in roots:
        for dp, dns, fns in os.walk(root):
            dns[:] = [d for d in dns if d not in SKIP_DIRS]
            for fn in fns:
                if (Path(fn).suffix.lower() in TEXT_EXT
                        and not is_report(str(Path(dp) / fn))
                        and not is_lab_material(str(Path(dp) / fn))):
                    p = Path(dp) / fn
                    try:
                        yield str(p), "text", p.read_text(encoding="utf-8", errors="ignore")
                    except OSError:
                        pass


def make_chunks(text: str, kind: str):
    """Список кусков: {text, kind, val}, где kind/val — «куда открывать» для kb -o."""
    chunks, buf, size, start, page, cur_page = [], [], 0, None, 1, 1

    def flush():
        nonlocal buf, size, start
        body = " ".join(buf).strip()
        if len(body) >= MIN_CHARS:
            if kind == "pdf":
                loc = ("page", page)
            elif kind in ("docx", "odt"):
                loc = ("para", max(start - 1, 1))      # в кэше первая строка служебная
            else:
                loc = ("line", start)
            chunks.append({"text": body, "kind": loc[0], "val": loc[1]})
        buf, size, start = [], 0, None

    for i, line in enumerate(text.split("\n"), start=1):
        if i == 1 and line.startswith("#SRC\t"):
            continue
        if kind == "pdf" and line.startswith("<<PAGE "):
            flush()
            cur_page = int(line[7:].split(">")[0])
            continue
        s = line.strip()
        if not s:
            continue
        if start is None:
            start, page = i, cur_page
        buf.append(s)
        size += len(s) + 1
        if size >= CHUNK_CHARS:
            flush()
    flush()
    return chunks


# ----------------------------------------------------------------- индекс на диске
def key_for(src: str) -> str:
    return hashlib.sha1(src.encode()).hexdigest()[:16]


def load_entry(path: Path, sig: str, model: str):
    if not path.exists():
        return None
    try:
        with np.load(path, allow_pickle=False) as z:
            if str(z["sig"]) == sig and str(z["model"]) == model:
                return z["vecs"], json.loads(str(z["meta"]))
    except Exception:
        return None
    return None


def build_index(cache: Path, roots, model: str, embed_getter):
    sem = cache / "sem"
    sem.mkdir(parents=True, exist_ok=True)
    # Разные эмбеддеры могут использовать одно и то же имя модели, но давать
    # векторы разной размерности (например, тестовый hash-эмбеддер).
    cache_model = f"{model}|embedder={os.environ.get('KB_EMBEDDER', 'default')}"
    entries, stale = [], []

    for src, kind, text in iter_sources(cache, roots):
        key = key_for(src)
        sig = hashlib.sha1(text.encode("utf-8", "ignore")).hexdigest()
        hit = load_entry(sem / f"{key}.npz", sig, cache_model)
        if hit is not None:
            entries.append((src, *hit))
        else:
            stale.append((src, kind, text, sig, key))

    if stale:
        embed = embed_getter()
        for n, (src, kind, text, sig, key) in enumerate(stale, start=1):
            print(f"🧮 [{n}/{len(stale)}] {Path(src).name}", file=sys.stderr)
            chunks = make_chunks(text, kind)
            vecs = embed([c["text"] for c in chunks]) if chunks else np.zeros((0, 1), dtype=np.float32)
            meta = [{"text": c["text"], "kind": c["kind"], "val": c["val"]} for c in chunks]
            tmp = sem / f"{key}.tmp.npz"
            np.savez(tmp, vecs=vecs, meta=np.array(json.dumps(meta, ensure_ascii=False)),
                     sig=np.array(sig), model=np.array(cache_model))
            os.replace(tmp, sem / f"{key}.npz")
            entries.append((src, vecs, meta))

    return entries


# ----------------------------------------------------------------- поиск
def shorten(text: str, n=150) -> str:
    return text if len(text) <= n else text[: n - 1] + "…"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", required=True)
    ap.add_argument("--roots", default="")
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("query", nargs="+")
    a = ap.parse_args()

    cache = Path(a.cache)
    roots = [r for r in a.roots.split(":") if r and Path(r).is_dir()]
    model = os.environ.get("KB_MODEL", DEFAULT_MODEL)
    query = " ".join(a.query)

    embedder = {}
    def embed_getter():
        if "e" not in embedder:
            embedder["e"] = get_embedder(model)
        return embedder["e"]

    entries = build_index(cache, roots, model, embed_getter)
    entries = [e for e in entries if len(e[2]) > 0]
    if not entries:
        print("Индекс пуст: нет текстов для поиска.")
        return 1

    mats = np.vstack([e[1] for e in entries])
    owners = [(si, ci) for si, e in enumerate(entries) for ci in range(len(e[2]))]
    q = embed_getter()([query])[0]
    scores = mats @ q
    order = np.argsort(-scores)

    last = cache / "last"
    rows, shown, per_file = [], 0, {}
    home = str(Path.home())
    best = float(scores[order[0]])
    if best < 0.05:
        print("Ничего похожего не нашлось.")
        return 1
    for idx in order:
        if float(scores[idx]) < 0.5 * best:      # хвост заведомо неподходящих результатов не показываем
            break
        si, ci = owners[idx]
        src, _, meta = entries[si]
        if per_file.get(src, 0) >= PER_FILE_LIMIT:
            continue
        per_file[src] = per_file.get(src, 0) + 1
        m = meta[ci]
        shown += 1
        loc = {"page": f"стр. {m['val']}", "para": f"абз. {m['val']}", "line": f"строка {m['val']}"}[m["kind"]]
        rows.append(f"{src}\t{m['kind']}\t{m['val']}")
        pretty = src.replace(home, "~", 1) if src.startswith(home) else src
        print(f"\033[1;36m[{shown}]\033[0m \033[1m{pretty}\033[0m  \033[2m{loc} · сходство {scores[idx]*100:.0f}%\033[0m")
        print(f"      {shorten(m['text'])}")
        if shown >= a.top:
            break
    last.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print("\nОткрыть: kb -o <номер>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
