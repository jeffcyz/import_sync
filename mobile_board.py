#!/usr/bin/env python3
"""encoder.py: input/ 里的所有文件 -> ZIP -> 1024x1024 RGB PNG (必要时拆成多张)"""
import argparse
import hashlib
import io
import struct
import sys
import zipfile
import zlib
from pathlib import Path

from PIL import Image

MAGIC = b"PNGX"
VERSION = 1
# 魔数 | 版本 | 整包SHA-256 | 总图片数 | 本图序号(从0) | 本图数据长度 | 整包长度 | 本图数据CRC32
HEADER_FMT = ">4sB32sIIIQI"
HEADER_SIZE = struct.calcsize(HEADER_FMT)  # 61 字节


def build_zip(input_dir: Path) -> bytes:
    files = sorted(p for p in input_dir.rglob("*") if p.is_file())
    if not files:
        sys.exit(f"错误：{input_dir} 中没有文件")
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for p in files:
            zf.write(p, p.relative_to(input_dir).as_posix())  # 中文文件名自动 UTF-8
    print(f"打包 {len(files)} 个文件，原始 {sum(p.stat().st_size for p in files):,} B"
          f" -> ZIP {buf.tell():,} B")
    return buf.getvalue()


def encode(input_dir: Path, output_dir: Path, size: int = 1024) -> list[Path]:
    payload = build_zip(input_dir)
    sha = hashlib.sha256(payload).digest()
    frame = size * size * 3                      # 每张图的总字节容量
    capacity = frame - HEADER_SIZE               # 扣除头部后的有效容量
    total = -(-len(payload) // capacity)         # 向上取整
    output_dir.mkdir(parents=True, exist_ok=True)

    outputs = []
    for i in range(total):
        chunk = payload[i * capacity:(i + 1) * capacity]
        header = struct.pack(HEADER_FMT, MAGIC, VERSION, sha, total, i,
                             len(chunk), len(payload), zlib.crc32(chunk))
        raw = (header + chunk).ljust(frame, b"\x00")   # 尾部补零
        img = Image.frombytes("RGB", (size, size), raw)
        out = output_dir / f"data_{sha.hex()[:8]}_{i + 1:03d}of{total:03d}.png"
        img.save(out, format="PNG", compress_level=6)  # PNG 无损；不能带 alpha / 缩放
        outputs.append(out)
        print(f"写入 {out.name}  ({out.stat().st_size:,} B)")
    print(f"完成：{total} 张图片，整包 SHA-256 = {sha.hex()}")
    return outputs


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="文件 -> 高密度 PNG")
    ap.add_argument("-i", "--input", default="input", type=Path)
    ap.add_argument("-o", "--output", default="encoded", type=Path)
    ap.add_argument("--size", default=1024, type=int, help="图片边长，默认 1024")
    a = ap.parse_args()
    encode(a.input, a.output, a.size)


#!/usr/bin/env python3
"""verify.py: 逐文件比较 input/ 与 recovered/ 的 SHA-256"""
import argparse
import hashlib
import sys
from pathlib import Path


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for blk in iter(lambda: f.read(1 << 20), b""):
            h.update(blk)
    return h.hexdigest()


def scan(root: Path) -> dict:
    return {p.relative_to(root).as_posix(): sha256(p)
            for p in sorted(root.rglob("*")) if p.is_file()}


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="校验恢复结果")
    ap.add_argument("-a", "--original", default="input", type=Path)
    ap.add_argument("-b", "--recovered", default="recovered", type=Path)
    a = ap.parse_args()
    A, B = scan(a.original), scan(a.recovered)
    ok = True
    for name in sorted(A.keys() | B.keys()):
        if name not in B:
            print(f"✘ 缺失   {name}"); ok = False
        elif name not in A:
            print(f"? 多出   {name}"); ok = False
        elif A[name] != B[name]:
            print(f"✘ 不一致 {name}"); ok = False
        else:
            print(f"✔ 一致   {name}  {A[name][:16]}…")
    print("\n全部字节完全一致 ✔" if ok else "\n校验失败 ✘")
    sys.exit(0 if ok else 1)



#!/usr/bin/env python3
"""decoder.py: encoded/ 里的 PNG -> 校验 -> 还原 ZIP -> 解压到 recovered/"""
import argparse
import hashlib
import struct
import sys
import zipfile
import zlib
from collections import defaultdict
from pathlib import Path

from PIL import Image

from encoder import HEADER_FMT, HEADER_SIZE, MAGIC


def read_png(path: Path):
    img = Image.open(path)
    if img.mode != "RGB":
        sys.exit(f"错误：{path.name} 模式为 {img.mode}，应为 RGB（图片可能被转换/重新压缩过）")
    raw = img.tobytes()
    magic, ver, sha, total, idx, clen, plen, crc = struct.unpack(HEADER_FMT, raw[:HEADER_SIZE])
    if magic != MAGIC:
        return None
    chunk = raw[HEADER_SIZE:HEADER_SIZE + clen]
    if len(chunk) != clen or zlib.crc32(chunk) != crc:
        sys.exit(f"错误：{path.name} 数据 CRC 校验失败（像素被修改，通常是图片被压缩或缩放）")
    return sha, total, idx, plen, chunk


def safe_extract(zf: zipfile.ZipFile, out: Path):
    root = out.resolve()
    for m in zf.infolist():
        target = (out / m.filename).resolve()
        if root != target and root not in target.parents:
            sys.exit(f"错误：ZIP 含非法路径 {m.filename}")
    zf.extractall(out)


def decode(encoded_dir: Path, output_dir: Path):
    groups = defaultdict(dict)   # sha -> {idx: chunk}
    meta = {}                    # sha -> (total, payload_len)
    for p in sorted(encoded_dir.glob("*.png")):
        r = read_png(p)
        if r is None:
            print(f"跳过 {p.name}（不是本工具生成的图片）")
            continue
        sha, total, idx, plen, chunk = r
        groups[sha][idx] = chunk
        meta[sha] = (total, plen)
    if not groups:
        sys.exit("错误：没有找到可解码的 PNG")

    for sha, chunks in groups.items():
        total, plen = meta[sha]
        missing = [i + 1 for i in range(total) if i not in chunks]
        if missing:
            sys.exit(f"错误：缺少第 {missing} 张图片（共 {total} 张）")
        payload = b"".join(chunks[i] for i in range(total))
        if len(payload) != plen or hashlib.sha256(payload).digest() != sha:
            sys.exit("错误：整包 SHA-256 校验失败")
        print(f"[{sha.hex()[:8]}] {total} 张图片，SHA-256 校验通过 ✔")

        dest = output_dir if len(groups) == 1 else output_dir / sha.hex()[:8]
        dest.mkdir(parents=True, exist_ok=True)
        zip_path = dest / "_recovered.zip"
        zip_path.write_bytes(payload)
        with zipfile.ZipFile(zip_path) as zf:
            safe_extract(zf, dest)
        zip_path.unlink()
        print(f"已恢复到 {dest}/")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="高密度 PNG -> 原始文件")
    ap.add_argument("-i", "--input", default="encoded", type=Path)
    ap.add_argument("-o", "--output", default="recovered", type=Path)
    a = ap.parse_args()
    decode(a.input, a.output)
