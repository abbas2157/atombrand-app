import 'package:flutter/material.dart';

/// Marketing copy for the signed-out screens, taken from
/// https://atomshop.pk/brand-partners. Keep it in step with that page.
class PartnerContent {
  const PartnerContent._();

  static const headline = 'Put your brand in orbit.';
  static const pitch =
      "Sell on Pakistan's fastest-growing Buy Now, Pay Later marketplace, to buyers ready to spend in instalments.";

  static const stats = [
    (value: '10K+', label: 'Active customers'),
    (value: '4–5K', label: 'Orders every month'),
    (value: '360+', label: 'Merchants live'),
    (value: '200K+', label: 'Community reach'),
  ];

  static const benefits = [
    (
      icon: Icons.trending_up_rounded,
      title: 'Lift your conversion',
      body: 'Instalments remove sticker shock. Shoppers who hesitate at full price check out when they can pay in steps.',
    ),
    (
      icon: Icons.public_rounded,
      title: 'Sell across Pakistan',
      body: 'Reach instalment-ready buyers nationwide, for retail and bulk orders.',
    ),
    (
      icon: Icons.storefront_rounded,
      title: 'Web & app storefront',
      body: 'Your products featured on the AtomShop website and app, with merchandising and search.',
    ),
    (
      icon: Icons.campaign_rounded,
      title: 'No extra ad spend',
      body: 'Tap our marketing engine and community without opening a new advertising budget.',
    ),
    (
      icon: Icons.account_balance_wallet_rounded,
      title: 'Keep control of recovery',
      body: 'We route buyers to you, and payment goes straight to your account.',
    ),
    (
      icon: Icons.verified_rounded,
      title: 'Build brand presence',
      body: "Grow recognition alongside Pakistan's trusted brands.",
    ),
  ];

  static const steps = [
    (title: 'Apply', body: 'Tell us about your brand, category and a few products. Takes two minutes.'),
    (title: 'Review', body: 'Our team verifies your details and agrees pricing and margins with you.'),
    (title: 'Go live', body: 'Your storefront goes up on web and app. Orders, and instalments, begin.'),
  ];

  static const whoCanApply = ['Established brands', 'Manufacturers', 'Authorised importers', 'Authorised distributors'];

  static const criteria = [
    'A registered, reputable business',
    'Genuine products only: no replicas or grey market',
    'At least 3 products to list',
    'Partner-friendly pricing and wholesale margins',
    'Reliable fulfilment: stock on hand, timely shipping',
  ];

  static const liveBrands = ['OXY', 'Atom Iron'];

  static const replyTime = '2 business days';
}
