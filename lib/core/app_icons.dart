import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every icon in the app, from Lucide (lucide.dev, ISC licence): 24 px grid,
/// 2 px round strokes. Use these names, never `Icons.*` or `LucideIcons.*`
/// directly, so the whole app keeps one style and can change in one place.
///
/// Lucide has no filled icons, so the active bottom tab uses the bolder 500
/// weight. Lucide also has no brand logos; the Facebook and Apple sign-in
/// buttons keep their real marks from Material.
abstract final class AppIcons {
  // Bottom navigation: regular when inactive, bold (500) when active.
  static const IconData home = LucideIcons.house;
  static const IconData homeFill = LucideIcons.house500;
  static const IconData orders = LucideIcons.receiptText;
  static const IconData ordersFill = LucideIcons.receiptText500;
  static const IconData bulk = LucideIcons.megaphone;
  static const IconData bulkFill = LucideIcons.megaphone500;
  static const IconData catalogue = LucideIcons.archive;
  static const IconData catalogueFill = LucideIcons.archive500;
  static const IconData more = LucideIcons.menu;
  static const IconData moreFill = LucideIcons.menu500;

  // Actions.
  static const IconData search = LucideIcons.search;
  static const IconData searchEmpty = LucideIcons.searchX;
  static const IconData add = LucideIcons.plus;
  static const IconData minus = LucideIcons.minus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData note = LucideIcons.notebookPen;
  static const IconData delete = LucideIcons.trash2;
  static const IconData share = LucideIcons.share2;
  static const IconData copy = LucideIcons.copy;
  static const IconData externalLink = LucideIcons.externalLink;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checks = LucideIcons.checkCheck;
  static const IconData checklist = LucideIcons.listChecks;
  static const IconData camera = LucideIcons.camera;
  static const IconData cameraAdd = LucideIcons.camera;
  static const IconData image = LucideIcons.image;
  static const IconData imageAdd = LucideIcons.imagePlus;
  static const IconData imageBroken = LucideIcons.imageOff;
  static const IconData gallery = LucideIcons.images;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData star = LucideIcons.star;
  static const IconData flag = LucideIcons.flag;
  static const IconData grid = LucideIcons.layoutGrid;
  static const IconData listView = LucideIcons.rows3;
  static const IconData bulletList = LucideIcons.list;
  static const IconData bold = LucideIcons.bold;
  static const IconData heading = LucideIcons.heading;

  // Communication.
  static const IconData phone = LucideIcons.phone;
  static const IconData phoneCall = LucideIcons.phoneCall;
  static const IconData chat = LucideIcons.messageCircleMore;
  static const IconData comment = LucideIcons.messageCircle;
  static const IconData email = LucideIcons.mail;
  static const IconData emailOpen = LucideIcons.mailOpen;
  static const IconData bell = LucideIcons.bell;
  static const IconData bellFill = LucideIcons.bell;
  static const IconData support = LucideIcons.headset;

  // Commerce and status.
  static const IconData tv = LucideIcons.tv;
  static const IconData microwave = LucideIcons.microwave;
  static const IconData package = LucideIcons.package;
  static const IconData packageFill = LucideIcons.package;
  static const IconData outOfStock = LucideIcons.packageX;
  static const IconData bag = LucideIcons.shoppingBag;
  static const IconData tag = LucideIcons.tag;
  static const IconData payments = LucideIcons.banknote;
  static const IconData wallet = LucideIcons.wallet;
  static const IconData bank = LucideIcons.landmark;
  static const IconData calendar = LucideIcons.calendarDays;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendUpArrow = LucideIcons.arrowUp;
  static const IconData trendDownArrow = LucideIcons.arrowDown;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData checkCircleFill = LucideIcons.circleCheck;
  static const IconData verified = LucideIcons.badgeCheck;
  static const IconData verifiedFill = LucideIcons.badgeCheck;
  static const IconData shieldCheck = LucideIcons.shieldCheck;
  static const IconData clock = LucideIcons.clock;
  static const IconData hourglass = LucideIcons.hourglass;
  static const IconData hourglassEmpty = LucideIcons.hourglass;
  static const IconData pauseCircle = LucideIcons.circlePause;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData info = LucideIcons.info;
  static const IconData xCircle = LucideIcons.circleX;
  static const IconData blocked = LucideIcons.ban;
  static const IconData offline = LucideIcons.cloudOff;
  static const IconData lock = LucideIcons.lock;
  static const IconData lockKey = LucideIcons.lockKeyhole;
  static const IconData tip = LucideIcons.lightbulb;
  static const IconData handshake = LucideIcons.handshake;
  static const IconData document = LucideIcons.fileText;

  // Account.
  static const IconData user = LucideIcons.user;
  static const IconData users = LucideIcons.users;
  static const IconData store = LucideIcons.store;
  static const IconData brandPage = LucideIcons.panelsTopLeft;
  static const IconData key = LucideIcons.key;
  static const IconData password = LucideIcons.keyRound;
  static const IconData logout = LucideIcons.logOut;
  static const IconData globe = LucideIcons.globe;
  static const IconData mobile = LucideIcons.smartphone;

  // Solid marks Lucide doesn't draw: a filled star for "featured", and the
  // real brand logos on the social sign-in buttons.
  static const IconData starFill = Icons.star_rounded;
  static const IconData facebook = Icons.facebook;
  static const IconData apple = Icons.apple;
}
