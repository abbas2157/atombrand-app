"""App Store product page Header asset (5244x2950).

Brand rules (DESIGN.md §1): the lockup is charcoal + red, sits on a light
surface, and is never recoloured or stretched. The diagonal slashes echo the
Welcome screen, as on the Play feature graphic.

Run: python3 store/appstore/make_header.py
"""

from PIL import Image, ImageDraw, ImageFont

W, H = 5244, 2950
INK = (27, 28, 30)
RED = (190, 30, 45)
MUTED = (100, 116, 139)
WHITE = (255, 255, 255)
FONT_PATH = '/System/Library/Fonts/SFNS.ttf'

OUT = 'store/appstore/header-5244x2950.png'
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

# --- Brand slashes, bleeding off the right edge -----------------------------
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


slash(W - 2250, 620, (*INK, 13))   # ~5%
slash(W - 1430, 420, (*RED, 20))   # ~8%
img.paste(Image.alpha_composite(img.convert('RGBA'), layer).convert('RGB'), (0, 0))
d = ImageDraw.Draw(img)

# --- Centred lockup ---------------------------------------------------------
lock = Image.open(LOCKUP).convert('RGBA')
lock = lock.crop(lock.getchannel('A').getbbox())
lock_h = 980
lock_w = round(lock_h * lock.width / lock.height)
lock = lock.resize((lock_w, lock_h), Image.LANCZOS)

eyebrow_f = font(74, 'Semibold')
head_f = font(250, 'Bold')
sub_f = font(104, 'Regular')

eyebrow = 'BRAND PARTNER APP'
head = 'Put your brand in orbit.'
sub = 'Orders, bulk requests, stock and your brand page.'

eyebrow_h, head_h, sub_h = 74, 250, 104
gap_lock, gap_eyebrow, gap_head = 150, 90, 80
block_h = lock_h + gap_lock + eyebrow_h + gap_eyebrow + head_h + gap_head + sub_h
y = (H - block_h) // 2

img.paste(lock, ((W - lock_w) // 2, y), lock)
y += lock_h + gap_lock

# red eyebrow bar + label, centred as one unit
bar_w, bar_h, bar_gap = 130, 18, 54
label_w = tracked_width(d, eyebrow, eyebrow_f, tracking=6.5)
unit_x = (W - (bar_w + bar_gap + label_w)) // 2
d.rounded_rectangle(
    [unit_x, y + 28, unit_x + bar_w, y + 28 + bar_h], radius=9, fill=RED
)
draw_tracked(d, (unit_x + bar_w + bar_gap, y), eyebrow, eyebrow_f, MUTED, tracking=6.5)
y += eyebrow_h + gap_eyebrow

d.text((W // 2, y), head, font=head_f, fill=INK, anchor='ma')
y += head_h + gap_head

d.text((W // 2, y), sub, font=sub_f, fill=MUTED, anchor='ma')

img.save(OUT)
print(f'{OUT}  {img.size[0]}x{img.size[1]}  mode={img.mode}')
