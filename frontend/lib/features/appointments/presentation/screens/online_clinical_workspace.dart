import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:hospital_management/data/remote/online_clinical_api.dart';

class OnlineClinicalWorkspace extends ConsumerStatefulWidget {
  const OnlineClinicalWorkspace({super.key});

  @override
  ConsumerState<OnlineClinicalWorkspace> createState() =>
      _OnlineClinicalWorkspaceState();
}

class _OnlineClinicalWorkspaceState
    extends ConsumerState<OnlineClinicalWorkspace> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Online clinical workspace')),
        body: IndexedStack(index: _tab, children: const [
          _OnlineAppointmentsPage(),
          _OnlineDepartmentsPage(),
          _OnlineDoctorsPage(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.event_note), label: 'Appointments'),
            NavigationDestination(
                icon: Icon(Icons.apartment), label: 'Departments'),
            NavigationDestination(
                icon: Icon(Icons.medical_services), label: 'Doctors'),
          ],
        ),
      );
}

abstract class _OnlinePageState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  bool loading = false;
  String? error;

  OnlineClinicalApi get api => ref.read(onlineClinicalApiProvider);

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action();
    } on OnlineApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted)
        setState(() => error =
            'The online request failed. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget pageState({required Widget child}) => Column(children: [
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          MaterialBanner(
            content: Text(error!),
            leading: const Icon(Icons.error_outline),
            actions: [
              TextButton(
                  onPressed: () => setState(() => error = null),
                  child: const Text('Dismiss'))
            ],
          ),
        Expanded(child: child),
      ]);
}

class _OnlineAppointmentsPage extends ConsumerStatefulWidget {
  const _OnlineAppointmentsPage();
  @override
  ConsumerState<_OnlineAppointmentsPage> createState() =>
      _OnlineAppointmentsPageState();
}

class _OnlineAppointmentsPageState
    extends _OnlinePageState<_OnlineAppointmentsPage> {
  List<Map<String, dynamic>> _items = const [];
  bool _loaded = false;

  Future<void> _load() => run(() async {
        _items = await api.appointments();
        _loaded = true;
      });

  Future<void> _book() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AppointmentBookingDialog(api: api),
    );
    if (created == true) await _load();
  }

  Future<void> _open(Map<String, dynamic> appointment) async {
    final id = appointment['appointmentUuid']?.toString();
    if (id == null) return;
    Map<String, dynamic> detail;
    try {
      detail = await api.appointment(id);
    } on OnlineApiException catch (e) {
      if (mounted) setState(() => error = e.message);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _AppointmentDetailDialog(
        api: api,
        appointment: detail,
        role: ref.read(onlineHospitalSessionProvider).user?.role ?? '',
        onChanged: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(onlineHospitalSessionProvider).user?.role ?? '';
    final canCreate =
        const {'HOSPITAL_SUPER_ADMIN', 'ADMIN', 'RECEPTIONIST'}.contains(role);
    if (!_loaded && !loading)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    return pageState(
        child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
              child: Text(
                  'Appointments are loaded from the authenticated Hospital API.',
                  style: Theme.of(context).textTheme.bodyMedium)),
          IconButton(
              onPressed: loading ? null : _load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh)),
          if (canCreate)
            FilledButton.icon(
                onPressed: loading ? null : _book,
                icon: const Icon(Icons.add),
                label: const Text('Book')),
        ]),
      ),
      Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(_loaded
                      ? 'No online appointments yet.'
                      : 'Loading appointmentsâ€¦'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.event)),
                        title: Text(
                            '${item['patientName'] ?? 'Patient'} Â· ${item['doctorName'] ?? 'Doctor'}'),
                        subtitle: Text(
                            '${item['startsAt'] ?? ''}  â€¢  ${item['status'] ?? ''}  â€¢  ${item['patientUhid'] ?? ''}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(item),
                      );
                    },
                  ))),
    ]));
  }
}

class _AppointmentBookingDialog extends StatefulWidget {
  const _AppointmentBookingDialog({required this.api});
  final OnlineClinicalApi api;
  @override
  State<_AppointmentBookingDialog> createState() =>
      _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends State<_AppointmentBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _patients = const [],
      _doctors = const [],
      _slots = const [];
  String? _patient, _doctor, _slot;
  String _type = 'CONSULTATION';
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait(
          [widget.api.patients(), widget.api.doctors(active: true)]);
      if (!mounted) return;
      _patients = results[0];
      _doctors = results[1];
      _patient = _patients.isEmpty ? null : _patients.first['uuid']?.toString();
      _doctor = _doctors.isEmpty ? null : _doctors.first['id']?.toString();
      _loading = false;
      if (_doctor != null)
        await _loadSlots();
      else
        setState(() {});
    } on OnlineApiException catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not load Patients and Doctors from the server.';
        });
    }
  }

  Future<void> _loadSlots() async {
    if (_doctor == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _slot = null;
    });
    try {
      _slots = await widget.api.availability(_doctor!, _date);
      if (mounted)
        setState(() {
          _loading = false;
        });
    } on OnlineApiException catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Availability could not be loaded.';
        });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _patient == null ||
        _doctor == null ||
        _slot == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.createAppointment({
        'patientUuid': _patient,
        'doctorUuid': _doctor,
        'startsAt': _slot,
        'appointmentType': _type,
        'reason': _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on OnlineApiException catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = 'Appointment could not be saved online.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Book online appointment'),
        content: SizedBox(
            width: 520,
            child: _loading
                ? const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()))
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      DropdownButtonFormField<String>(
                          value: _patient,
                          decoration:
                              const InputDecoration(labelText: 'Patient'),
                          items: _patients
                              .map((p) => DropdownMenuItem(
                                  value: p['uuid']?.toString(),
                                  child: Text(
                                      '${p['name'] ?? 'Patient'} Â· ${p['uhid'] ?? ''}')))
                              .toList(),
                          onChanged: (v) => setState(() => _patient = v),
                          validator: (v) => v == null
                              ? 'No online Patient is available.'
                              : null),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          value: _doctor,
                          decoration:
                              const InputDecoration(labelText: 'Doctor'),
                          items: _doctors
                              .map((d) => DropdownMenuItem(
                                  value: d['id']?.toString(),
                                  child: Text(
                                      '${d['displayName'] ?? 'Doctor'} Â· ${d['specialization'] ?? ''}')))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _doctor = v;
                            });
                            _loadSlots();
                          },
                          validator: (v) => v == null
                              ? 'No active Doctor is available.'
                              : null),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: Text(
                                'Hospital date: ${_date.toIso8601String().substring(0, 10)}')),
                        TextButton(
                            onPressed: () async {
                              final chosen = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)));
                              if (chosen != null) {
                                setState(
                                    () => _date = DateUtils.dateOnly(chosen));
                                await _loadSlots();
                              }
                            },
                            child: const Text('Choose date'))
                      ]),
                      DropdownButtonFormField<String>(
                          value: _slot,
                          decoration: const InputDecoration(
                              labelText: 'Available slot (Hospital timezone)'),
                          items: _slots
                              .map((s) => DropdownMenuItem(
                                  value: s['startsAt']?.toString(),
                                  child: Text(
                                      '${s['localStartTime']} â€“ ${s['localEndTime']}')))
                              .toList(),
                          onChanged: (v) => setState(() => _slot = v),
                          validator: (v) => v == null
                              ? 'Select a server-available slot.'
                              : null),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(
                              labelText: 'Appointment type'),
                          items: const ['CONSULTATION', 'FOLLOW_UP', 'OTHER']
                              .map((v) =>
                                  DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _type = v);
                          }),
                      TextFormField(
                          controller: _reason,
                          decoration:
                              const InputDecoration(labelText: 'Reason'),
                          maxLength: 500),
                      TextFormField(
                          controller: _notes,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          maxLength: 2000,
                          maxLines: 2),
                    ])))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Close')),
          FilledButton(
              onPressed: _saving || _loading ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Book'))
        ],
      );
}

class _AppointmentDetailDialog extends StatefulWidget {
  const _AppointmentDetailDialog(
      {required this.api,
      required this.appointment,
      required this.role,
      required this.onChanged});
  final OnlineClinicalApi api;
  final Map<String, dynamic> appointment;
  final String role;
  final Future<void> Function() onChanged;
  @override
  State<_AppointmentDetailDialog> createState() =>
      _AppointmentDetailDialogState();
}

class _AppointmentDetailDialogState extends State<_AppointmentDetailDialog> {
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> events = const [];
  String get id => widget.appointment['appointmentUuid'].toString();

  Future<void> _act(Future<dynamic> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action();
      await widget.onChanged();
      if (mounted) Navigator.pop(context);
    } on OnlineApiException catch (e) {
      if (mounted)
        setState(() {
          loading = false;
          error = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          error = 'The server could not complete this change.';
        });
    }
  }

  Future<void> _history() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      events = await widget.api.appointmentEvents(id);
    } on OnlineApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Event history could not be loaded.';
    }
    if (mounted)
      setState(() {
        loading = false;
      });
  }

  List<String> _transitions(String status) {
    final admin = const {'HOSPITAL_SUPER_ADMIN', 'ADMIN'}.contains(widget.role);
    final receptionist = widget.role == 'RECEPTIONIST';
    final doctor = widget.role == 'DOCTOR';
    return switch (status) {
      'SCHEDULED' when admin || receptionist => ['CONFIRMED', 'CANCELLED'],
      'CONFIRMED' when admin || receptionist => [
          'CHECKED_IN',
          'CANCELLED',
          'NO_SHOW'
        ],
      'CHECKED_IN' when admin || doctor => ['IN_PROGRESS'],
      'IN_PROGRESS' when admin || doctor => ['COMPLETED'],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.appointment;
    final transitions = _transitions(item['status']?.toString() ?? '');
    final canManage = const {'HOSPITAL_SUPER_ADMIN', 'ADMIN', 'RECEPTIONIST'}
        .contains(widget.role);
    return AlertDialog(
        title: const Text('Online appointment'),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  if (loading) const LinearProgressIndicator(),
                  if (error != null)
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  Text(
                      'Patient: ${item['patientName'] ?? ''} (${item['patientUhid'] ?? ''})'),
                  Text('Doctor: ${item['doctorName'] ?? ''}'),
                  Text(
                      'Time: ${item['startsAt'] ?? ''} â€“ ${item['endsAt'] ?? ''}'),
                  Text('Status: ${item['status'] ?? ''}'),
                  Text('Type: ${item['appointmentType'] ?? ''}'),
                  if ((item['reason'] ?? '').toString().isNotEmpty)
                    Text('Reason: ${item['reason']}'),
                  const SizedBox(height: 12),
                  TextButton.icon(
                      onPressed: loading ? null : _history,
                      icon: const Icon(Icons.history),
                      label: const Text('Load event history')),
                  ...events.map((e) => ListTile(
                      dense: true,
                      title: Text(e['eventType']?.toString() ?? 'Event'),
                      subtitle: Text(
                          '${e['previousStatus'] ?? ''} â†’ ${e['newStatus'] ?? ''} Â· ${e['occurredAt'] ?? ''}'))),
                  if (transitions.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                        'Available transitions (server enforces permissions):'),
                    Wrap(
                        spacing: 8,
                        children: transitions
                            .map((status) => OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => _act(() => widget.api
                                        .changeAppointmentStatus(id, status)),
                                child: Text(status.replaceAll('_', ' '))))
                            .toList()),
                  ],
                  if (canManage &&
                      (item['status'] == 'SCHEDULED' ||
                          item['status'] == 'CONFIRMED'))
                    TextButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)));
                                if (date == null || !context.mounted) return;
                                final availability = await widget.api
                                    .availability(
                                        item['doctorUuid'].toString(), date);
                                if (!context.mounted) return;
                                if (availability.isEmpty) {
                                  setState(() => error =
                                      'No server-available slots on that date.');
                                  return;
                                }
                                final startsAt = await showDialog<String>(
                                  context: context,
                                  builder: (context) => SimpleDialog(
                                    title:
                                        const Text('Choose an available slot'),
                                    children: availability
                                        .map((slot) => SimpleDialogOption(
                                              onPressed: () => Navigator.pop(
                                                  context,
                                                  slot['startsAt'].toString()),
                                              child: Text(
                                                  '${slot['localStartTime']} – ${slot['localEndTime']}'),
                                            ))
                                        .toList(),
                                  ),
                                );
                                if (startsAt == null || !context.mounted)
                                  return;
                                await _act(
                                    () => widget.api.reschedule(id, startsAt));
                              },
                        icon: const Icon(Icons.schedule),
                        label: const Text('Reschedule to next available slot')),
                  if (canManage &&
                      item['status'] != 'CANCELLED' &&
                      item['status'] != 'COMPLETED')
                    TextButton.icon(
                        onPressed: loading
                            ? null
                            : () =>
                                _act(() => widget.api.cancelAppointment(id)),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel appointment')),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ]);
  }
}

class _OnlineDepartmentsPage extends ConsumerStatefulWidget {
  const _OnlineDepartmentsPage();
  @override
  ConsumerState<_OnlineDepartmentsPage> createState() =>
      _OnlineDepartmentsPageState();
}

class _OnlineDepartmentsPageState
    extends _OnlinePageState<_OnlineDepartmentsPage> {
  List<Map<String, dynamic>> _items = const [];
  bool _loaded = false;
  Future<void> _load() => run(() async {
        _items = await api.departments();
        _loaded = true;
      });

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name']?.toString());
    final code = TextEditingController(text: item?['code']?.toString());
    final description =
        TextEditingController(text: item?['description']?.toString());
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title:
                  Text(item == null ? 'Create Department' : 'Edit Department'),
              content: SizedBox(
                  width: 420,
                  child: Form(
                      key: formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            controller: name,
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required.'
                                : null),
                        TextFormField(
                            controller: code,
                            decoration:
                                const InputDecoration(labelText: 'Code'),
                            validator: (v) => v == null || v.trim().length < 2
                                ? 'Enter a valid code.'
                                : null),
                        TextFormField(
                            controller: description,
                            decoration: const InputDecoration(
                                labelText: 'Description')),
                      ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate())
                        Navigator.pop(context, true);
                    },
                    child: const Text('Save'))
              ],
            ));
    if (save == true)
      await run(() async {
        final body = {
          'name': name.text.trim(),
          'code': code.text.trim(),
          'description':
              description.text.trim().isEmpty ? null : description.text.trim()
        };
        if (item == null) {
          await api.createDepartment(body);
        } else {
          await api.updateDepartment(item['id'].toString(), body);
        }
        _items = await api.departments();
        _loaded = true;
      });
    name.dispose();
    code.dispose();
    description.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(onlineHospitalSessionProvider).user?.role ?? '';
    final canManage = const {'HOSPITAL_SUPER_ADMIN', 'ADMIN'}.contains(role);
    if (!_loaded && !loading)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    return pageState(
        child: Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Expanded(
                child: Text('Hospital-scoped Departments from the backend.')),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canManage)
              FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'))
          ])),
      Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(_loaded
                      ? 'No Departments found.'
                      : 'Loading Departmentsâ€¦'))
              : ListView(
                  children: _items
                      .map((item) => ListTile(
                            title: Text('${item['name']} (${item['code']})'),
                            subtitle:
                                Text(item['description']?.toString() ?? ''),
                            trailing: Wrap(children: [
                              if (canManage)
                                IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => _edit(item),
                                    icon: const Icon(Icons.edit)),
                              if (canManage)
                                Switch(
                                    value: item['active'] == true,
                                    onChanged: (value) => run(() async {
                                          await api.setDepartmentActive(
                                              item['id'].toString(), value);
                                          _items = await api.departments();
                                        }))
                            ]),
                          ))
                      .toList())),
    ]));
  }
}

class _OnlineDoctorsPage extends ConsumerStatefulWidget {
  const _OnlineDoctorsPage();
  @override
  ConsumerState<_OnlineDoctorsPage> createState() => _OnlineDoctorsPageState();
}

class _OnlineDoctorsPageState extends _OnlinePageState<_OnlineDoctorsPage> {
  List<Map<String, dynamic>> _items = const [];
  bool _loaded = false;
  Future<void> _load() => run(() async {
        _items = await api.doctors();
        _loaded = true;
      });

  Future<void> _create() async {
    final membership = TextEditingController(),
        specialization = TextEditingController(),
        qualification = TextEditingController();
    final departments = await api.departments(active: true);
    String? departmentId;
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: const Text('Create Doctor profile'),
                  content: SizedBox(
                      width: 450,
                      child: SingleChildScrollView(
                          child: Form(
                              key: formKey,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'Select an existing active DOCTOR Membership. Account creation is managed separately.'),
                                    TextFormField(
                                        controller: membership,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Doctor Membership UUID'),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Membership UUID is required.'
                                                : null),
                                    DropdownButtonFormField<String>(
                                        value: departmentId,
                                        decoration: const InputDecoration(
                                            labelText: 'Department (optional)'),
                                        items: departments
                                            .map((d) => DropdownMenuItem(
                                                value: d['id'].toString(),
                                                child:
                                                    Text(d['name'].toString())))
                                            .toList(),
                                        onChanged: (v) => setDialogState(
                                            () => departmentId = v)),
                                    TextFormField(
                                        controller: specialization,
                                        decoration: const InputDecoration(
                                            labelText: 'Specialization'),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Required.'
                                                : null),
                                    TextFormField(
                                        controller: qualification,
                                        decoration: const InputDecoration(
                                            labelText: 'Qualification'),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Required.'
                                                : null),
                                  ])))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (formKey.currentState!.validate())
                            Navigator.pop(context, true);
                        },
                        child: const Text('Create'))
                  ],
                )));
    if (save == true)
      await run(() async {
        await api.createDoctor({
          'membershipId': membership.text.trim(),
          'departmentId': departmentId,
          'specialization': specialization.text.trim(),
          'qualification': qualification.text.trim()
        });
        _items = await api.doctors();
        _loaded = true;
      });
    membership.dispose();
    specialization.dispose();
    qualification.dispose();
  }

  Future<void> _editProfile(Map<String, dynamic> item) async {
    final specialization =
        TextEditingController(text: item['specialization']?.toString());
    final qualification =
        TextEditingController(text: item['qualification']?.toString());
    final registration =
        TextEditingController(text: item['registrationReference']?.toString());
    final departments = await api.departments(active: true);
    String? departmentId = item['departmentId']?.toString();
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Doctor profile'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: departmentId,
                  decoration:
                      const InputDecoration(labelText: 'Department (optional)'),
                  items: departments
                      .map((d) => DropdownMenuItem(
                          value: d['id'].toString(),
                          child: Text(d['name'].toString())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => departmentId = v),
                ),
                TextFormField(
                    controller: specialization,
                    decoration:
                        const InputDecoration(labelText: 'Specialization'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required.' : null),
                TextFormField(
                    controller: qualification,
                    decoration:
                        const InputDecoration(labelText: 'Qualification'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required.' : null),
                TextFormField(
                    controller: registration,
                    decoration: const InputDecoration(
                        labelText: 'Registration reference (optional)')),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (save == true) {
      await run(() async {
        await api.updateDoctor(item['id'].toString(), {
          'departmentId': departmentId,
          'specialization': specialization.text.trim(),
          'qualification': qualification.text.trim(),
          'registrationReference': registration.text.trim().isEmpty
              ? null
              : registration.text.trim(),
        });
        _items = await api.doctors();
        _loaded = true;
      });
    }
    specialization.dispose();
    qualification.dispose();
    registration.dispose();
  }

  Future<void> _manage(Map<String, dynamic> doctor) async {
    final role = ref.read(onlineHospitalSessionProvider).user?.role ?? '';
    final canManage = const {'HOSPITAL_SUPER_ADMIN', 'ADMIN'}.contains(role);
    await showDialog<void>(
        context: context,
        builder: (_) => _DoctorScheduleDialog(
            api: api, doctor: doctor, canManage: canManage));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(onlineHospitalSessionProvider).user?.role ?? '';
    final canManage = const {'HOSPITAL_SUPER_ADMIN', 'ADMIN'}.contains(role);
    if (!_loaded && !loading)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    return pageState(
        child: Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Expanded(
                child: Text(
                    'Doctor Profiles and schedules are managed by the online API.')),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canManage)
              FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add),
                  label: const Text('Link Doctor Membership'))
          ])),
      Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(_loaded
                      ? 'No Doctor profiles found.'
                      : 'Loading Doctorsâ€¦'))
              : ListView(
                  children: _items
                      .map((item) => ListTile(
                            title: Text(
                                item['displayName']?.toString() ?? 'Doctor'),
                            subtitle: Text(
                                '${item['specialization'] ?? ''} Â· ${item['qualification'] ?? ''} Â· ${item['departmentName'] ?? 'No department'}'),
                            trailing: Wrap(children: [
                              if (canManage)
                                IconButton(
                                    tooltip: 'Edit Doctor profile',
                                    onPressed: () => _editProfile(item),
                                    icon: const Icon(Icons.edit)),
                              if (canManage)
                                Switch(
                                    value: item['active'] == true,
                                    onChanged: (value) => run(() async {
                                          await api.setDoctorActive(
                                              item['id'].toString(), value);
                                          _items = await api.doctors();
                                        })),
                              IconButton(
                                  tooltip: 'Schedules and availability',
                                  onPressed: () => _manage(item),
                                  icon: const Icon(Icons.calendar_month))
                            ]),
                          ))
                      .toList())),
    ]));
  }
}

class _DoctorScheduleDialog extends StatefulWidget {
  const _DoctorScheduleDialog(
      {required this.api, required this.doctor, required this.canManage});
  final OnlineClinicalApi api;
  final Map<String, dynamic> doctor;
  final bool canManage;
  @override
  State<_DoctorScheduleDialog> createState() => _DoctorScheduleDialogState();
}

class _DoctorScheduleDialogState extends State<_DoctorScheduleDialog> {
  List<Map<String, dynamic>> schedules = const [],
      exceptions = const [],
      slots = const [];
  bool loading = true;
  String? error;
  final date = DateUtils.dateOnly(DateTime.now());
  String get id => widget.doctor['id'].toString();

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await Future.wait([
        widget.api.schedules(id),
        widget.api.exceptions(id),
        widget.api.availability(id, date)
      ]);
      schedules = result[0];
      exceptions = result[1];
      slots = result[2];
    } on OnlineApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Doctor schedule information could not be loaded.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _toggleSchedule(Map<String, dynamic> schedule) async {
    try {
      await widget.api.updateSchedule(id, schedule['id'].toString(), {
        'dayOfWeek': schedule['dayOfWeek'],
        'startTime': schedule['startTime'],
        'endTime': schedule['endTime'],
        'slotMinutes': schedule['slotMinutes'],
        'effectiveFrom': schedule['effectiveFrom'],
        'effectiveUntil': schedule['effectiveUntil'],
        'active': schedule['active'] != true,
      });
      await _load();
    } on OnlineApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  Future<void> _toggleException(Map<String, dynamic> exception) async {
    try {
      await widget.api.updateException(id, exception['id'].toString(), {
        'date': exception['date'],
        'type': exception['type'],
        'startTime': exception['startTime'],
        'endTime': exception['endTime'],
        'reason': exception['reason'],
        'active': exception['active'] != true,
      });
      await _load();
    } on OnlineApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  Future<void> _addSchedule([Map<String, dynamic>? existing]) async {
    final form = GlobalKey<FormState>();
    var day = (existing?['dayOfWeek'] as num?)?.toInt() ?? 1;
    var slotMinutes = (existing?['slotMinutes'] as num?)?.toInt() ?? 30;
    final start = TextEditingController(
        text: existing?['startTime']?.toString().substring(0, 5) ?? '09:00');
    final end = TextEditingController(
        text: existing?['endTime']?.toString().substring(0, 5) ?? '17:00');
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: Text(existing == null
                      ? 'Add recurring schedule'
                      : 'Edit recurring schedule'),
                  content: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        DropdownButtonFormField<int>(
                            value: day,
                            decoration:
                                const InputDecoration(labelText: 'Day of week'),
                            items: List.generate(
                                7,
                                (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(const [
                                      'Monday',
                                      'Tuesday',
                                      'Wednesday',
                                      'Thursday',
                                      'Friday',
                                      'Saturday',
                                      'Sunday'
                                    ][i]))),
                            onChanged: (v) => setDialog(() => day = v ?? 1)),
                        TextFormField(
                            controller: start,
                            decoration: const InputDecoration(
                                labelText: 'Start time (HH:mm)')),
                        TextFormField(
                            controller: end,
                            decoration: const InputDecoration(
                                labelText: 'End time (HH:mm)')),
                        DropdownButtonFormField<int>(
                            value: slotMinutes,
                            decoration: const InputDecoration(
                                labelText: 'Server schedule slot duration'),
                            items: const [15, 20, 30, 45, 60]
                                .map((v) => DropdownMenuItem(
                                    value: v, child: Text('$v minutes')))
                                .toList(),
                            onChanged: (v) =>
                                setDialog(() => slotMinutes = v ?? 30)),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Save'))
                  ],
                )));
    if (save == true) {
      try {
        if (existing != null) {
          await widget.api.updateSchedule(id, existing['id'].toString(), {
            'dayOfWeek': day,
            'startTime': '${start.text}:00',
            'endTime': '${end.text}:00',
            'slotMinutes': slotMinutes,
            'effectiveFrom': existing['effectiveFrom'],
            'effectiveUntil': existing['effectiveUntil'],
            'active': existing['active'] == true,
          });
        } else {
          await widget.api.createSchedule(id, {
            'dayOfWeek': day,
            'startTime': '${start.text}:00',
            'endTime': '${end.text}:00',
            'slotMinutes': slotMinutes,
            'effectiveFrom': DateTime.now().toIso8601String().substring(0, 10),
            'active': true,
          });
        }
        await _load();
      } on OnlineApiException catch (e) {
        if (mounted) setState(() => error = e.message);
      }
    }
    start.dispose();
    end.dispose();
  }

  Future<void> _addException() async {
    var type = 'LEAVE';
    final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (selectedDate == null || !mounted) {
      return;
    }
    final reason = TextEditingController();
    final selectedType = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: const Text('Schedule exception'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<String>(
                          initialValue: type,
                          items: const ['LEAVE', 'BLOCKED']
                              .map((v) =>
                                  DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => type = v ?? 'LEAVE')),
                      TextField(
                          controller: reason,
                          decoration: const InputDecoration(
                              labelText: 'Reason (optional)')),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, type),
                          child: const Text('Continue'))
                    ])));
    if (selectedType == null) {
      reason.dispose();
      return;
    }
    TimeOfDay? start;
    TimeOfDay? end;
    if (selectedType == 'BLOCKED') {
      start = await showTimePicker(
          context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
      if (start == null || !mounted) {
        reason.dispose();
        return;
      }
      end = await showTimePicker(
          context: context,
          initialTime:
              TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute));
      if (end == null || !mounted) {
        reason.dispose();
        return;
      }
    }
    try {
      await widget.api.createException(id, {
        'date': selectedDate.toIso8601String().substring(0, 10),
        'type': selectedType,
        'startTime': start == null
            ? null
            : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
        'endTime': end == null
            ? null
            : '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
        'reason': reason.text.trim().isEmpty ? null : reason.text.trim(),
        'active': true
      });
      await _load();
    } on OnlineApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
    reason.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text('${widget.doctor['displayName'] ?? 'Doctor'} schedule'),
          content: SizedBox(
              width: 560,
              child: loading
                  ? const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()))
                  : SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          if (error != null)
                            Text(error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          Row(children: [
                            const Expanded(child: Text('Recurring schedules')),
                            if (widget.canManage)
                              IconButton(
                                  onPressed: _addSchedule,
                                  icon: const Icon(Icons.add))
                          ]),
                          ...schedules.map((s) => ListTile(
                              dense: true,
                              title: Text(
                                  'Day ${s['dayOfWeek']}: ${s['startTime']}â€“${s['endTime']}'),
                              subtitle: Text(
                                  '${s['slotMinutes']} minute slots Â· from ${s['effectiveFrom']}'))),
                          Row(children: [
                            const Expanded(
                                child: Text('Leave / blocked dates')),
                            if (widget.canManage)
                              IconButton(
                                  onPressed: _addException,
                                  icon: const Icon(Icons.add))
                          ]),
                          ...exceptions.map((e) => ListTile(
                              dense: true,
                              title: Text('${e['date']} Â· ${e['type']}'),
                              subtitle: Text(e['reason']?.toString() ?? ''))),
                          const Divider(),
                          Text(
                              'Availability for ${date.toIso8601String().substring(0, 10)} (server is authoritative)'),
                          if (slots.isEmpty)
                            const Text('No available slots for today.')
                          else
                            ...slots.map((s) => Text(
                                '${s['localStartTime']}â€“${s['localEndTime']}')),
                        ]))),
          actions: [
            TextButton(onPressed: _load, child: const Text('Refresh')),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ]);
}
