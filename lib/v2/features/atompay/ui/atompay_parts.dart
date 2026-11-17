import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../data/atompay_models.dart';

/// The tone of an AtomPay step (the boards' `.stage` colours).
AtomTone atompayTone(AtompayStep s) => switch (s) {
  AtompayStep.approving => AtomTone.blue,
  AtompayStep.seller => AtomTone.grey,
  AtompayStep.handover => AtomTone.amber,
  AtompayStep.handed => const AtomTone(
    fg: Color(0xFF0E6B73),
    bg: Color(0xFFE6F4F5),
    border: Color(0xFFE6F4F5),
  ),
  AtompayStep.paid => AtomTone.green,
  AtompayStep.cancelled => AtomTone.rose,
};

/// The seller's initials in a small round tile (`.ini`); "?" before
/// Atomshop gives one.
class SellerInitials extends StatelessWidget {
  const SellerInitials({super.key, required this.seller});
  final AtompaySeller? seller;

  @override
  Widget build(BuildContext context) {
    final none = seller == null;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: none ? AtomColors.surface : AtomColors.primarySoft,
      ),
      child: Text(
        none ? '?' : seller!.initials,
        style: AtomText.tag.copyWith(
          color: none ? AtomColors.faint : AtomColors.primary,
        ),
      ),
    );
  }
}
