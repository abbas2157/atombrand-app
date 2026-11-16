"""App Store marketing screenshots.

Takes raw simulator captures, substitutes the live partner's data for a
fictional brand, and composites each onto a branded canvas with a headline.

Raw captures are read from SHOTS (outside the repo: they contain real
customer data and must not be committed). Only the substituted composites
are written into store/appstore/screenshots/.

Run: python3 store/appstore/make_screenshots.py
"""

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SHOTS = os.environ.get(
    'SHOTS',
    '/private/tmp/claude-501/-Users-muhammadjaved-Projects-atombrand-app/'
    'b217ecba-e520-40b1-92b1-451b23e416e9/scratchpad/shots',
)
OUT_DIR = 'store/appstore/screenshots'

INK = (27, 28, 30)
RED = (190, 30, 45)
MUTED = (100, 116, 139)
WHITE = (255, 255, 255)
PAGE = (244, 245, 249)
FONT_PATH = '/System/Library/Fonts/SFNS.ttf'


def font(size, weight='Regular'):
    f = ImageFont.truetype(FONT_PATH, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def patch(d, box, fill):
    """Paint over a region before redrawing substituted text."""
    d.rectangle(box, fill=fill)


# Fictional stand-ins for the live partner's catalogue.
NOVA_PRODUCTS = [
    'NOVA 4318L Smart TV',
    'NOVA 3218L Android',
    'NOVA 4318F Smart TV',
    'NOVA 4018 Android TV',
    'NOVA 5518G Smart TV',
]


# --- Substitution ----------------------------------------------------------
# The signed-in account is a live partner (OXY). Every identifying value is
# replaced with a fictional brand before the capture goes anywhere public.

def scrub_iphone_dashboard(im):
    d = ImageDraw.Draw(im)
    s = im.width / 1320  # these coordinates were measured on a 1320px capture

    # Header: brand name, greeting and logo badge.
    patch(d, (int(170 * s), int(215 * s), int(700 * s), int(320 * s)), INK)
    d.text((int(186 * s), int(222 * s)), 'NOVA', font=font(int(50 * s), 'Semibold'), fill=WHITE)
    d.text((int(186 * s), int(286 * s)), 'Hi, Nova', font=font(int(34 * s), 'Regular'), fill=(165, 168, 174))
    d.ellipse(
        (int(52 * s), int(222 * s), int(146 * s), int(316 * s)), fill=RED
    )
    d.text(
        (int(99 * s), int(252 * s)), 'NV', font=font(int(34 * s), 'Bold'), fill=WHITE, anchor='ma'
    )

    # Order value card: the partner's real revenue.
    patch(d, (int(90 * s), int(1020 * s), int(630 * s), int(1170 * s)), WHITE)
    d.text((int(96 * s), int(1024 * s)), 'Rs. 1,284,500', font=font(int(62 * s), 'Bold'), fill=INK)
    d.text((int(96 * s), int(1119 * s)), 'Order value (18 orders)', font=font(int(32 * s), 'Regular'), fill=MUTED)

    # Latest order row: product name carries the brand, thumbnail is their photography.
    patch(d, (int(60 * s), int(2330 * s), int(1270 * s), int(2500 * s)), WHITE)
    d.rounded_rectangle(
        (int(74 * s), int(2338 * s), int(247 * s), int(2482 * s)), radius=int(10 * s), fill=(236, 238, 243)
    )
    d.text((int(265 * s), int(2355 * s)), 'NOVA 4318L Smart TV', font=font(int(44 * s), 'Semibold'), fill=INK)
    d.text((int(265 * s), int(2425 * s)), 'Rs. 72,000', font=font(int(42 * s), 'Bold'), fill=INK)
    return im


def scrub_iphone_orders(im):
    d = ImageDraw.Draw(im)
    s = im.width / 1320
    names = [
        'NOVA 4318L Smart TV', 'NOVA 4318F Smart TV', 'NOVA 4318L Smart TV',
        'NOVA 3218L Android', 'NOVA 3218L Android',
    ]
    for i, name in enumerate(names):
        top = 899 + i * 329
        # Thumbnail is the partner's product photography.
        d.rounded_rectangle(
            (int(74 * s), int((top + 34) * s), int(244 * s), int((top + 188) * s)),
            radius=int(10 * s), fill=(236, 238, 243),
        )
        # Product name carries the brand.
        patch(d, (int(258 * s), int((top + 46) * s), int(900 * s), int((top + 104) * s)), WHITE)
        d.text((int(262 * s), int((top + 50) * s)), name, font=font(int(44 * s), 'Semibold'), fill=INK)
    return im


def scrub_iphone_catalogue(im):
    d = ImageDraw.Draw(im)
    s = im.width / 1320
    names = [
        'NOVA 4318L Smart TV', 'NOVA 4318F Smart TV', 'NOVA 5018 N1 (Black)',
        'NOVA 43N01 Android', 'NOVA 5518G Smart TV', 'NOVA 7518G Smart TV',
    ]
    for i, name in enumerate(names):
        top = 860 + i * 315
        d.rounded_rectangle(
            (int(74 * s), int((top + 48) * s), int(262 * s), int((top + 216) * s)),
            radius=int(10 * s), fill=(236, 238, 243),
        )
        patch(d, (int(283 * s), int((top + 48) * s), int(1000 * s), int((top + 108) * s)), WHITE)
        d.text((int(285 * s), int((top + 50) * s)), name, font=font(int(46 * s), 'Semibold'), fill=INK)
    return im


def scrub_ipad_orders(im):
    d = ImageDraw.Draw(im)
    for i in range(9):
        top = 558 + i * 219
        d.rounded_rectangle((52, top + 6, 154, top + 108), radius=8, fill=(236, 238, 243))
        patch(d, (166, top + 10, 900, top + 50), WHITE)
        d.text((170, top + 12), NOVA_PRODUCTS[i % len(NOVA_PRODUCTS)], font=font(30, 'Semibold'), fill=INK)
    return im


def scrub_ipad_dashboard(im):
    d = ImageDraw.Draw(im)
    # Header brand name and greeting.
    patch(d, (120, 85, 700, 160), INK)
    d.text((126, 88), 'NOVA', font=font(40, 'Semibold'), fill=WHITE)
    d.text((126, 134), 'Hi, Nova', font=font(28, 'Regular'), fill=(165, 168, 174))
    d.ellipse((30, 86, 106, 162), fill=RED)
    d.text((68, 108), 'NV', font=font(28, 'Bold'), fill=WHITE, anchor='ma')

    # Order value card.
    patch(d, (1065, 300, 1560, 420), WHITE)
    d.text((1068, 302), 'Rs. 1,284,500', font=font(52, 'Bold'), fill=INK)
    d.text((1068, 377), 'Order value (18 orders)', font=font(26, 'Regular'), fill=MUTED)

    # Latest orders + Top products lists both carry brand names and thumbnails.
    for i, name in enumerate(NOVA_PRODUCTS):
        top = 891 + i * 183
        d.rounded_rectangle((52, top - 4, 154, top + 104), radius=8, fill=(236, 238, 243))
        patch(d, (165, top + 12, 900, top + 52), WHITE)
        d.text((167, top + 14), name, font=font(28, 'Semibold'), fill=INK)
    for i, name in enumerate(NOVA_PRODUCTS):
        top = 1935 + i * 114
        d.rounded_rectangle((52, top - 2, 154, top + 80), radius=8, fill=(236, 238, 243))
        patch(d, (165, top + 8, 900, top + 50), WHITE)
        d.text((167, top + 12), name, font=font(28, 'Semibold'), fill=INK)
    return im


# --- Marketing canvas ------------------------------------------------------

def compose(shot, headline, sub, out_path, radius_pt=70):
    W, H = shot.size
    canvas = Image.new('RGB', (W, H), WHITE)

    # Brand slashes, bleeding off the right edge.
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    lean = H * 0.30
    for x_bottom, width, colour in (
        (W - int(W * 0.42), int(W * 0.12), (*INK, 12)),
        (W - int(W * 0.26), int(W * 0.08), (*RED, 18)),
    ):
        ld.polygon(
            [(x_bottom, H), (x_bottom + width, H),
             (x_bottom + width + lean, 0), (x_bottom + lean, 0)],
            fill=colour,
        )
    canvas = Image.alpha_composite(canvas.convert('RGBA'), layer).convert('RGB')
    d = ImageDraw.Draw(canvas)

    # Headline block.
    head_f = font(int(W * 0.062), 'Bold')
    sub_f = font(int(W * 0.030), 'Regular')
    y = int(H * 0.048)
    for line in headline:
        d.text((W // 2, y), line, font=head_f, fill=INK, anchor='ma')
        y += int(W * 0.075)
    y += int(W * 0.012)
    d.text((W // 2, y), sub, font=sub_f, fill=MUTED, anchor='ma')

    # Device plate: rounded screenshot with a soft shadow, bleeding off the bottom.
    plate_w = int(W * 0.80)
    plate_h = round(plate_w * H / W)
    plate = shot.resize((plate_w, plate_h), Image.LANCZOS)
    radius = round(radius_pt * plate_w / W)

    mask = Image.new('L', (plate_w, plate_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, plate_w - 1, plate_h - 1), radius=radius, fill=255)

    # Sit the plate so the tab bar stays inside the frame.
    px, py = (W - plate_w) // 2, H - plate_h - int(H * 0.012)

    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (px + 6, py + 18, px + plate_w - 6, py + plate_h), radius=radius, fill=(27, 28, 30, 70)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(W * 0.018)))
    canvas = Image.alpha_composite(canvas.convert('RGBA'), shadow).convert('RGB')

    canvas.paste(plate, (px, py), mask)
    canvas.save(out_path)
    return out_path


# App Store Connect slot sizes. iPhone captures come off a 6.9" simulator
# (1320x2868) and are scaled to the 6.3" slot; iPad is already a listed size.
IPHONE_SLOT = (1206, 2622)
IPAD_SLOT = (2064, 2752)

SPECS = [
    ('iphone-dashboard.png', scrub_iphone_dashboard,
     ['Your whole brand,', 'at a glance.'],
     'Orders, stock and bulk leads the moment you open it.',
     '01-iphone-dashboard.png'),
    ('iphone-orders-retail.png', scrub_iphone_orders,
     ['Every order,', 'retail and instalment.'],
     'Filter by status, search by product, act in a tap.',
     '02-iphone-orders.png'),
    ('iphone-catalogue.png', scrub_iphone_catalogue,
     ['Products and stock,', 'under control.'],
     'Add, edit and restock without leaving your phone.',
     '03-iphone-catalogue.png'),
    ('ipad-dashboard.png', scrub_ipad_dashboard,
     ['Your whole brand, at a glance.'],
     'Orders, stock and bulk leads the moment you open it.',
     '01-ipad-dashboard.png'),
    ('ipad-orders.png', scrub_ipad_orders,
     ['Every order, retail and instalment.'],
     'Filter by status, search by product, act in a tap.',
     '02-ipad-orders.png'),
]

if __name__ == '__main__':
    os.makedirs(OUT_DIR, exist_ok=True)
    for src, scrub, headline, sub, dest in SPECS:
        im = Image.open(os.path.join(SHOTS, src)).convert('RGB')
        if scrub:
            im = scrub(im)
        # Scrub at capture resolution, then scale to the store slot so the
        # headline is drawn at the final size rather than resampled.
        slot = IPAD_SLOT if 'ipad' in src else IPHONE_SLOT
        if im.size != slot:
            im = im.resize(slot, Image.LANCZOS)
        path = compose(im, headline, sub, os.path.join(OUT_DIR, dest))
        print(f'{path}  {Image.open(path).size}')
