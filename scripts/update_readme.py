import re, pathlib

readme        = pathlib.Path(__file__).parent.parent / 'README.md'
content       = readme.read_text()

marker_start  = '<!-- screenshot-start -->'
marker_end    = '<!-- screenshot-end -->'
image_ref     = '![Home Screen](screenshots/home-screen.png)'

block   = f'{marker_start}\n{image_ref}\n{marker_end}'
pattern = re.compile(
    rf'{re.escape(marker_start)}.*?{re.escape(marker_end)}',
    re.DOTALL
)

if pattern.search(content):
    content = pattern.sub(block, content)
else:
    content = content.rstrip('\n') + '\n\n' + block + '\n'

readme.write_text(content)
