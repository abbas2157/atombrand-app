import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// What the update feature remembers between launches.
///
/// Public data only (the server's policy, when the seller last closed a
/// banner), so a plain file in the app's own storage rather than the
/// Keystore: nothing here is secret, and a launch never waits on the
/// Keystore to decide about updates.
@immutable
class UpdateMemory {
  const UpdateMemory({
    this.policy,
    this.policyAt,
    this.stale = false,
    this.lookupVersion,
    this.lookupAt,
    this.gentleClosedAt,
    this.gentleClosedFor,
    this.flexibleAskedAt,
    this.flexibleAskedFor,
    this.immediateAskedAt,
    this.immediateAskedFor,
    this.lastSeenBuild,
  });

  /// The last `seller.update.<platform>` the server sent, as JSON.
  final Map<String, dynamic>? policy;
  final DateTime? policyAt;

  /// Atomshop said to check again (`app_update` push) before [policyAt]
  /// runs out.
  final bool stale;

  /// iOS: what the App Store said it has, and when.
  final String? lookupVersion;
  final DateTime? lookupAt;

  /// The seller closed the "update available" banner, for this build.
  final DateTime? gentleClosedAt;
  final int? gentleClosedFor;

  /// Google Play's download prompt was shown, for this version code.
  final DateTime? flexibleAskedAt;
  final int? flexibleAskedFor;
  final DateTime? immediateAskedAt;
  final int? immediateAskedFor;

  /// The build that ran last time: a higher one now means the app was
  /// just updated, and What's new shows once.
  final int? lastSeenBuild;

  UpdateMemory copyWith({
    Map<String, dynamic>? policy,
    DateTime? policyAt,
    bool? stale,
    String? lookupVersion,
    DateTime? lookupAt,
    DateTime? gentleClosedAt,
    int? gentleClosedFor,
    DateTime? flexibleAskedAt,
    int? flexibleAskedFor,
    DateTime? immediateAskedAt,
    int? immediateAskedFor,
    int? lastSeenBuild,
  }) => UpdateMemory(
    policy: policy ?? this.policy,
    policyAt: policyAt ?? this.policyAt,
    stale: stale ?? this.stale,
    lookupVersion: lookupVersion ?? this.lookupVersion,
    lookupAt: lookupAt ?? this.lookupAt,
    gentleClosedAt: gentleClosedAt ?? this.gentleClosedAt,
    gentleClosedFor: gentleClosedFor ?? this.gentleClosedFor,
    flexibleAskedAt: flexibleAskedAt ?? this.flexibleAskedAt,
    flexibleAskedFor: flexibleAskedFor ?? this.flexibleAskedFor,
    immediateAskedAt: immediateAskedAt ?? this.immediateAskedAt,
    immediateAskedFor: immediateAskedFor ?? this.immediateAskedFor,
    lastSeenBuild: lastSeenBuild ?? this.lastSeenBuild,
  );

  Map<String, dynamic> toJson() => {
    'policy': policy,
    'policy_at': policyAt?.toIso8601String(),
    'stale': stale,
    'lookup_version': lookupVersion,
    'lookup_at': lookupAt?.toIso8601String(),
    'gentle_closed_at': gentleClosedAt?.toIso8601String(),
    'gentle_closed_for': gentleClosedFor,
    'flexible_asked_at': flexibleAskedAt?.toIso8601String(),
    'flexible_asked_for': flexibleAskedFor,
    'immediate_asked_at': immediateAskedAt?.toIso8601String(),
    'immediate_asked_for': immediateAskedFor,
    'last_seen_build': lastSeenBuild,
  };

  factory UpdateMemory.fromJson(Map<String, dynamic> j) {
    DateTime? at(String k) => DateTime.tryParse('${j[k] ?? ''}');
    int? n(String k) => j[k] is int ? j[k] as int : null;
    return UpdateMemory(
      policy: j['policy'] is Map
          ? Map<String, dynamic>.from(j['policy'] as Map)
          : null,
      policyAt: at('policy_at'),
      stale: j['stale'] == true,
      lookupVersion: j['lookup_version'] as String?,
      lookupAt: at('lookup_at'),
      gentleClosedAt: at('gentle_closed_at'),
      gentleClosedFor: n('gentle_closed_for'),
      flexibleAskedAt: at('flexible_asked_at'),
      flexibleAskedFor: n('flexible_asked_for'),
      immediateAskedAt: at('immediate_asked_at'),
      immediateAskedFor: n('immediate_asked_for'),
      lastSeenBuild: n('last_seen_build'),
    );
  }
}

/// Where [UpdateMemory] is kept.
abstract interface class UpdateStore {
  Future<UpdateMemory> read();
  Future<void> write(UpdateMemory memory);
}

/// `update.json` in the app's support folder. Unreadable or missing reads
/// as nothing remembered; a failed write is not an error.
class FileUpdateStore implements UpdateStore {
  const FileUpdateStore();

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'update.json'));
  }

  @override
  Future<UpdateMemory> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const UpdateMemory();
      final j = jsonDecode(await f.readAsString());
      return j is Map
          ? UpdateMemory.fromJson(Map<String, dynamic>.from(j))
          : const UpdateMemory();
    } catch (e) {
      debugPrint('[update] could not read what was kept: $e');
      return const UpdateMemory();
    }
  }

  @override
  Future<void> write(UpdateMemory memory) async {
    try {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(memory.toJson()), flush: true);
      await tmp.rename(f.path);
    } catch (e) {
      debugPrint('[update] could not keep: $e');
    }
  }

  /// Atomshop said to check again (a push that arrived with the app in
  /// the background): the next open asks the server instead of using what
  /// it kept.
  static Future<void> markStale() async {
    const store = FileUpdateStore();
    await store.write((await store.read()).copyWith(stale: true));
  }
}

/// Tests: kept in memory.
class MemoryUpdateStore implements UpdateStore {
  MemoryUpdateStore([this.memory = const UpdateMemory()]);
  UpdateMemory memory;

  @override
  Future<UpdateMemory> read() async => memory;

  @override
  Future<void> write(UpdateMemory memory) async => this.memory = memory;
}
