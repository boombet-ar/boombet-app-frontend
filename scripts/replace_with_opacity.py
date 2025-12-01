from pathlib import Path
import re

def convert(text: str) -> str:
    pattern = re.compile(r"\.withOpacity\(([^)]+)\)")
    return pattern.sub(r'.withValues(alpha: \1)', text)

root = Path('lib')
for dart in root.rglob('*.dart'):
    content = dart.read_text(encoding='utf-8')
    new_content = convert(content)
    if new_content != content:
        dart.write_text(new_content, encoding='utf-8')
        print(f"updated {dart}")
