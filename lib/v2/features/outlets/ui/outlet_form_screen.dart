import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../team/data/team_models.dart';
import '../../team/data/team_repository.dart';
import '../../team/ui/team_parts.dart' show TeamToggleChip, TeamFormFrame;
import '../data/outlet_models.dart';
import '../data/outlet_rules.dart';
import '../data/outlets_repository.dart';

/// Add outlet (11.8), or change one ([outlet]): its name, phone, city,
/// opening date (new only), who runs it (with the Team add-on: a
/// switched-on member, who becomes its Outlet manager), address and the
/// cities it serves. A city another outlet serves shows as taken.
class OutletFormScreen extends ConsumerStatefulWidget {
  const OutletFormScreen({super.key, this.outlet});

  final BrandOutlet? outlet;

  @override
  ConsumerState<OutletFormScreen> createState() => _OutletFormScreenState();
}

class _OutletFormScreenState extends ConsumerState<OutletFormScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  late final _name = TextEditingController(text: widget.outlet?.name);
  late final _phone = TextEditingController(text: widget.outlet?.phone);
  late final _address = TextEditingController(text: widget.outlet?.address);
  late City? _city = widget.outlet?.city;
  late Map<int, String> _cities = {
    for (final c in widget.outlet?.cities ?? const <City>[]) c.id: c.title,
  };
  DateTime _openedOn = AtomDates.now();

  /// The team member picked to run it, once the owner picks one; until
  /// then the one who runs it now.
  int? _managerPick;
  bool _managerTouched = false;

  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _error;

  bool get _isNew => widget.outlet == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  /// The member who runs it now: the form options' word, else their user
  /// id on the outlet matched in the team list.
  int? _currentManager(List<TeamMember>? members, OutletFormOptions? options) {
    if (options?.currentManagerId case final id?) return id;
    final uid = widget.outlet?.managerUserId;
    if (uid == null || members == null) return null;
    return members.where((m) => m.userId == uid).firstOrNull?.id;
  }

  bool _dirty(int? manager, int? current) {
    final o = widget.outlet;
    if (o == null) {
      return _name.text.trim().isNotEmpty ||
          _phone.text.trim().isNotEmpty ||
          _address.text.trim().isNotEmpty ||
          _city != null ||
          _cities.isNotEmpty;
    }
    final before = {for (final c in o.cities) c.id};
    return _name.text.trim() != o.name ||
        _phone.text.trim() != (o.phone ?? '') ||
        _address.text.trim() != (o.address ?? '') ||
        _city?.id != o.city?.id ||
        before.length != _cities.length ||
        !before.containsAll(_cities.keys) ||
        manager != current;
  }

  void _changed([String? field]) => setState(() {
    if (field != null && _errors.containsKey(field)) {
      _errors = {..._errors}..remove(field);
    }
    _error = null;
  });

  static const _fields = {
    'name',
    'phone',
    'city_id',
    'address',
    'city_ids',
    'opened_on',
    'manager_id',
  };

  Future<void> _save(OutletDraft draft) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
      _errors = const {};
    });
    final repo = ref.read(outletsRepositoryProvider);
    final r = _isNew
        ? await repo.add(draft)
        : await repo.update(widget.outlet!.id, draft);
    if (!mounted) return;
    switch (r) {
      case ApiOk(:final value):
        refreshOutlets(ref);
        ref.invalidate(teamListProvider);
        // The outlet switcher and the account's outlets come from GET me.
        ref.read(accessProvider.notifier).refresh();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: _isNew ? '${value.name} is open' : l.outletsSaved,
        );
        Navigator.of(context).pop();
      case ApiErr(:final failure):
        final shown = {
          for (final e in failure.fieldErrors.entries)
            if (_fields.contains(e.key.split('.').first))
              e.key.split('.').first: e.value,
        };
        setState(() {
          _saving = false;
          _errors = shown;
          _error = shown.isEmpty ? sayFailure(l, failure) : null;
        });
    }
  }

  Future<void> _pickOpened() async {
    final now = AtomDates.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedOn,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    _openedOn = picked;
    _changed('opened_on');
  }

  Future<void> _pickCities(List<City> all, Map<int, String> taken) async {
    final picked = await showAtomMultiSelect<int>(
      context,
      title: l.outletsCitiesServes,
      searchHint: l.outletsSearchCities,
      selected: _cities.keys.toSet(),
      options: [
        for (final c in all)
          if (!taken.containsKey(c.id)) AtomOption(value: c.id, label: c.title),
      ],
    );
    if (picked == null || !mounted) return;
    final names = {for (final c in all) c.id: c.title};
    _cities = {for (final id in picked) id: names[id] ?? ''};
    _changed('city_ids');
  }

  Widget? _fieldError(String key) => _errors[key] == null
      ? null
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_errors[key]!, style: AtomText.fieldError),
        );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    final list = ref.watch(outletListProvider(OutletPeriod.month)).value;
    // `outlets/form-options` first; an older server without it (null)
    // falls back to the site's cities, the outlet list and the team list.
    final optionsData = ref.watch(outletFormOptionsProvider(widget.outlet?.id));
    final options = optionsData.value;
    final useOptions = options != null && options.cities.isNotEmpty;
    final citiesData = useOptions
        ? AsyncValue<List<City>>.data(options.cities)
        : (optionsData.isLoading
              ? const AsyncValue<List<City>>.loading()
              : ref.watch(citiesProvider));
    final hasTeam = ref.watch(accessProvider).has(Addon.team);
    final members = hasTeam && options == null
        ? ref.watch(teamListProvider).value?.members
        : null;
    final current = _currentManager(members, options);
    final manager = _managerTouched ? _managerPick : current;
    final taken = useOptions
        ? options.taken
        : takenCities(list?.outlets ?? const [], selfId: widget.outlet?.id);
    final isMain = widget.outlet?.isMain ?? false;
    final allCities = citiesData.value ?? const <City>[];

    final blocker = outletFormBlocker(
      l,
      name: _name.text,
      phone: _phone.text,
      cityId: _city?.id,
      address: _address.text,
      isMain: isMain,
    );
    final dirty = _dirty(manager, current);
    final String button;
    VoidCallback? onSave;
    if (!online) {
      button = l.outletsNeedsInternet;
    } else if (blocker != null) {
      button = blocker;
    } else if (!_isNew && !dirty) {
      button = l.outletsNoChanges;
    } else {
      button = _isNew ? l.outletsSaveOutlet : l.outletsSaveChanges;
      onSave = () => _save(
        OutletDraft(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          cityId: _city!.id,
          address: _address.text.trim(),
          cityIds: _cities.keys.toList(),
          openedOn: _isNew ? _openedOn : null,
          managerId: manager,
          sendManager: manager != null && manager != current,
        ),
      );
    }

    // Who can run it: the form options' managers (switched-on members),
    // else the team list's switched-on members.
    final choices = <OutletManagerChoice>[
      if (options != null)
        ...options.managers
      else
        for (final m in members ?? const <TeamMember>[])
          if (!m.isOff) (id: m.id, name: m.name, role: m.role?.name),
    ];
    final managerName = manager == null
        ? null
        : choices.where((m) => m.id == manager).firstOrNull?.name;

    final name = AtomTextField(
      label: l.outletsName,
      controller: _name,
      error: _errors['name'],
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      textInputAction: TextInputAction.next,
      onChanged: (_) => _changed('name'),
    );
    final phone = AtomTextField(
      label: l.outletsPhone,
      controller: _phone,
      placeholder: '0300 1234567',
      keyboardType: TextInputType.phone,
      inputFormatters: [LengthLimitingTextInputFormatter(20)],
      error:
          _errors['phone'] ??
          (_phone.text.replaceAll(RegExp(r'\D'), '').length >= 11
              ? phoneProblem(l, _phone.text)
              : null),
      onChanged: (_) => _changed('phone'),
    );
    final city = AtomSelectField<int>(
      label: l.outletsCity,
      value: _city?.id,
      valueLabel: _city?.title,
      placeholder: l.outletsChooseCity,
      sheetTitle: l.outletsCity,
      searchHint: l.outletsSearchCities,
      offline: !online,
      error:
          _errors['city_id'] ??
          (citiesData.hasError ? l.outletsCitiesFailed : null),
      load: () async {
        final all = useOptions
            ? options.cities
            : await ref.read(citiesProvider.future);
        return [for (final c in all) AtomOption(value: c.id, label: c.title)];
      },
      onChanged: (id) {
        final c =
            (useOptions
                    ? options.cities
                    : (ref.read(citiesProvider).value ?? allCities))
                .where((x) => x.id == id)
                .firstOrNull;
        if (c == null) return;
        _city = c;
        // The city it is in is the first one it serves, unless taken.
        if (_cities.isEmpty && !taken.containsKey(c.id)) {
          _cities = {c.id: c.title};
        }
        _changed('city_id');
      },
    );
    final opened = AtomField(
      label: l.outletsOpenedOn,
      error: _errors['opened_on'],
      child: AtomSelectBox(
        text: AtomDates.day(_openedOn),
        semanticLabel: l.outletsOpenedOn,
        onTap: _pickOpened,
      ),
    );
    final runs = hasTeam
        ? AtomSelectField<int>(
            label: l.outletsWhoRunsIt,
            value: manager ?? 0,
            valueLabel: managerName ?? l.outletsNobody,
            sheetTitle: l.outletsWhoRunsIt,
            hint: manager != null && manager != current
                ? l.outletsManagerHint
                : null,
            error: _errors['manager_id'],
            options: [
              if (current == null) AtomOption(value: 0, label: l.outletsNobody),
              for (final m in choices)
                AtomOption(value: m.id, label: m.name, subtitle: m.role),
            ],
            onChanged: (id) {
              _managerTouched = true;
              _managerPick = id == 0 ? null : id;
              _changed('manager_id');
            },
          )
        : null;
    final wide =
        MediaQuery.sizeOf(context).width >= 400 &&
        MediaQuery.textScalerOf(context).scale(10) < 13;

    Widget two(Widget a, Widget? b) => b == null
        ? a
        : wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: AtomSpace.s3),
              Expanded(child: b),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              a,
              const SizedBox(height: AtomSpace.s3),
              b,
            ],
          );

    // Chips: what is picked, the city it is in when free, then the taken
    // ones greyed out so the owner sees who serves them.
    final suggested =
        _city != null &&
            !_cities.containsKey(_city!.id) &&
            !taken.containsKey(_city!.id)
        ? _city
        : null;
    final takenShown = [
      for (final e in taken.entries)
        (
          e.key,
          allCities.where((c) => c.id == e.key).firstOrNull?.title,
          e.value,
        ),
    ].where((t) => t.$2 != null).take(6);

    return TeamFormFrame(
      title: _isNew ? l.outletsAddOutlet : l.outletsEditOutlet,
      subtitle: _isNew && list != null
          ? l.outletsUsedLine(list.used, list.limit)
          : null,
      dirty: dirty,
      saving: _saving,
      button: button,
      onSave: onSave,
      error: _error,
      children: [
        name,
        const SizedBox(height: AtomSpace.s3),
        two(phone, city),
        const SizedBox(height: AtomSpace.s3),
        if (_isNew || runs != null) ...[
          two(_isNew ? opened : runs!, _isNew ? runs : null),
          const SizedBox(height: AtomSpace.s3),
        ],
        AtomTextField(
          label: l.outletsAddress,
          controller: _address,
          error: _errors['address'],
          inputFormatters: [LengthLimitingTextInputFormatter(250)],
          onChanged: (_) => _changed('address'),
        ),
        const SizedBox(height: AtomSpace.s4),
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(l.outletsCitiesServes, style: AtomText.fieldLabel),
            Text(l.outletsOneOutletPerCity, style: AtomText.small),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: AtomSpace.s2,
          runSpacing: AtomSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final e in _cities.entries)
              TeamToggleChip(
                label: e.value,
                on: true,
                onTap: () {
                  _cities = {..._cities}..remove(e.key);
                  _changed('city_ids');
                },
              ),
            if (suggested != null)
              TeamToggleChip(
                label: suggested.title,
                on: false,
                onTap: () {
                  _cities = {..._cities, suggested.id: suggested.title};
                  _changed('city_ids');
                },
              ),
            for (final (_, title, outlet) in takenShown)
              Semantics(
                label: l.outletsTakenAria(title!, outlet),
                excludeSemantics: true,
                child: TeamToggleChip(
                  label: l.outletsTakenBy(title, shortOutletName(outlet)),
                  on: false,
                  onTap: null,
                ),
              ),
            AtomButton.small(
              label: l.outletsAllCities,
              icon: LucideIcons.search,
              onPressed: allCities.isEmpty || !online
                  ? null
                  : () => _pickCities(allCities, taken),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l.outletsCitiesHint,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
        ?_fieldError('city_ids'),
        if (_isNew && list != null) ...[
          const SizedBox(height: AtomSpace.s4),
          AtomInfoCard(
            lines: [
              AtomInfoLine(
                label: l.outletsAccount,
                value: l.outletsMultiOutlet,
              ),
              AtomInfoLine(
                label: l.outletsOutletsUsed,
                value: l.outletsOfLimit(list.used, list.limit),
              ),
              AtomInfoLine(
                label: l.outletsAfterSaving,
                value: l.outletsOfLimit(list.used + 1, list.limit),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
