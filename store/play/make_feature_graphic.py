"""Play Store feature graphic (1024x500).

Brand rules (DESIGN.md §1): the lockup is charcoal + red and must sit on a
light surface, and is never recoloured or stretched. The faint diagonal
slashes echo the Welcome screen.

Run: python3 store/play/make_feature_graphic.py
"""

from PIL import Image, ImageDraw, ImageFont

W, H = 1024, 500
INK = (27, 28, 30)
RED = (190, 30, 45)
MUTED = (100, 116, 139)
WHITE = (255, 255, 255)
FONT_PATH = '/System/Library/Fonts/SFNS.ttf'

OUT = 'store/play/feature-graphic.png'
LOCKUP = 'assets/brand/lockup.png'


def font(size, weight='Regular'):
    f = ImageFont.truetype(FONT_PATH, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def draw_tracked(d, xy, s, f, fill, tracking=0.0):
    """Letter-spaced text; PIL has no tracking of its own."""
    x, y = xy
    for ch in s:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + tracking
    return x


def tracked_width(d, s, f, tracking=0.0):
    return sum(d.textlength(c, font=f) for c in s) + tracking * max(len(s) - 1, 0)


img = Image.new('RGB', (W, H), WHITE)
d = ImageDraw.Draw(img)

# --- Brand slashes, bleeding off the top-right corner -----------------------
layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ld = ImageDraw.Draw(layer)


def slash(x_bottom, width, colour):
    """Parallelogram leaning right, matching the Welcome screen painter."""
    lean = H * 0.58
    ld.polygon(
        [
            (x_bottom, H),
            (x_bottom + width, H),
            (x_bottom + width + lean, 0),
            (x_bottom + lean, 0),
        ],
        fill=colour,
    )


slash(W - 470, 128, (*INK, 15))    # ~6%
slash(W - 300, 86, (*RED, 23))     # ~9%
img.paste(Image.alpha_composite(img.convert('RGBA'), layer).convert('RGB'), (0, 0))
d = ImageDraw.Draw(img)

# --- Lockup, right side -----------------------------------------------------
lock = Image.open(LOCKUP).convert('RGBA')
lock = lock.crop(lock.getchannel('A').getbbox())
lock_h = 196
lock_w = round(lock_h * lock.width / lock.height)
lock = lock.resize((lock_w, lock_h), Image.LANCZOS)
lock_x = W - 96 - lock_w
img.paste(lock, (lock_x, (H - lock_h) // 2), lock)

# --- Copy, left side --------------------------------------------------------
x = 88
eyebrow_f = font(19, 'Semibold')
head_f = font(54, 'Bold')
sub_f = font(24, 'Regular')

head_lines = ['Put your brand', 'in orbit.']
sub_lines = ['Orders, bulk requests, stock', 'and your brand page.']

eyebrow_h = 19
head_lh = 62
sub_lh = 34
block_h = eyebrow_h + 26 + head_lh * len(head_lines) + 22 + sub_lh * len(sub_lines)
y = (H - block_h) // 2

# red eyebrow bar + label
bar_w, bar_h = 34, 5
d.rounded_rectangle([x, y + 7, x + bar_w, y + 7 + bar_h], radius=3, fill=RED)
draw_tracked(d, (x + bar_w + 14, y), 'BRAND PARTNER APP', eyebrow_f, MUTED, tracking=1.6)
y += eyebrow_h + 26

for line in head_lines:
    d.text((x, y), line, font=head_f, fill=INK)
    y += head_lh
y += 22

for line in sub_lines:
    d.text((x, y), line, font=sub_f, fill=MUTED)
    y += sub_lh

img.save(OUT)
print(f'{OUT}  {img.size[0]}x{img.size[1]}')
