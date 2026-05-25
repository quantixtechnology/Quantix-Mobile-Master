import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'provisioning_provider.dart';
import 'tenant_provision_model.dart';

class ProvisioningScreen extends ConsumerWidget {
  const ProvisioningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provisioningProvider);
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Provisioning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(provisioningProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Tenant'),
        backgroundColor: primary,
        onPressed: () => _showProvisionDialog(context, ref, primary),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(provisioningProvider.notifier).refresh(),
              child: _body(context, state, primary),
            ),
    );
  }

  Widget _body(BuildContext context, ProvisioningState state, Color primary) {
    if (!state.serviceAvailable) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Provision service unreachable',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Start mobile-provision service on :3400',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    if (state.error != null && state.tenants.isEmpty) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (state.tenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No tenants provisioned yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + New Tenant to get started',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.error != null)
          _ErrorBanner(message: state.error!),
        _SummaryRow(tenants: state.tenants),
        const SizedBox(height: 16),
        ...state.tenants.map((t) => _TenantCard(tenant: t, primary: primary)),
      ],
    );
  }

  void _showProvisionDialog(BuildContext context, WidgetRef ref, Color primary) {
    showDialog<void>(
      context: context,
      builder: (_) => _ProvisionDialog(primary: primary, ref: ref),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<TenantProvision> tenants;
  const _SummaryRow({required this.tenants});

  @override
  Widget build(BuildContext context) {
    final ready = tenants.where((t) => t.status == BuildStatus.ready).length;
    final building = tenants.where((t) => t.status == BuildStatus.building).length;
    final failed = tenants.where((t) => t.status == BuildStatus.failed).length;

    return Row(
      children: [
        _Chip('$ready Ready', Colors.green),
        const SizedBox(width: 8),
        _Chip('$building Building', Colors.blue),
        const SizedBox(width: 8),
        _Chip('$failed Failed', Colors.red),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
}

// ── Tenant card ───────────────────────────────────────────────────────────────
class _TenantCard extends StatelessWidget {
  final TenantProvision tenant;
  final Color primary;
  const _TenantCard({required this.tenant, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _StatusIcon(status: tenant.status),
        title: Text(tenant.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(tenant.slug,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: _StatusChip(status: tenant.status),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _StatusRow(
                  icon: Icons.palette_outlined,
                  label: 'Branding',
                  value: tenant.brandingStatus,
                  good: tenant.brandingStatus == 'DONE',
                ),
                _StatusRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Firebase',
                  value: tenant.firebaseStatus,
                  good: tenant.firebaseStatus == 'CONFIGURED',
                ),
                _StatusRow(
                  icon: Icons.build_outlined,
                  label: 'Build',
                  value: tenant.status.label,
                  good: tenant.status == BuildStatus.ready,
                  bad: tenant.status == BuildStatus.failed,
                ),
                if (tenant.repoUrl != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(Icons.code_outlined, 'Repo', tenant.repoUrl!),
                ],
                if (tenant.apkUrl != null) ...[
                  const SizedBox(height: 4),
                  _InfoRow(Icons.android_outlined, 'APK', tenant.apkUrl!),
                ],
                if (tenant.aabUrl != null) ...[
                  const SizedBox(height: 4),
                  _InfoRow(Icons.inventory_2_outlined, 'AAB', tenant.aabUrl!),
                ],
                if (tenant.error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tenant.error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12, fontFamily: 'monospace')),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Package: ${tenant.packageId}   ·   Created: ${_fmt(tenant.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _StatusIcon extends StatelessWidget {
  final BuildStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      BuildStatus.ready => (Icons.check_circle_outline, Colors.green),
      BuildStatus.failed => (Icons.error_outline, Colors.red),
      BuildStatus.building => (Icons.sync_outlined, Colors.blue),
      BuildStatus.provisioning => (Icons.settings_outlined, Colors.orange),
      BuildStatus.pending => (Icons.schedule_outlined, Colors.grey),
    };
    return Icon(icon, color: color);
  }
}

class _StatusChip extends StatelessWidget {
  final BuildStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BuildStatus.ready => ('READY', Colors.green),
      BuildStatus.failed => ('FAILED', Colors.red),
      BuildStatus.building => ('BUILDING', Colors.blue),
      BuildStatus.provisioning => ('PROVISIONING', Colors.orange),
      BuildStatus.pending => ('PENDING', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool good;
  final bool bad;
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.good = false,
    this.bad = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = bad ? Colors.red : good ? Colors.green : Colors.orange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.warning_amber_outlined, color: Colors.red),
          title: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ),
      );
}

// ── Provision dialog ──────────────────────────────────────────────────────────
class _ProvisionDialog extends StatefulWidget {
  final Color primary;
  final WidgetRef ref;
  const _ProvisionDialog({required this.primary, required this.ref});

  @override
  State<_ProvisionDialog> createState() => _ProvisionDialogState();
}

class _ProvisionDialogState extends State<_ProvisionDialog> {
  final _form = GlobalKey<FormState>();
  final _businessId = TextEditingController();
  final _slug = TextEditingController();
  final _name = TextEditingController();
  final _primaryColor = TextEditingController(text: '#00B14F');
  String _businessType = 'generic';
  bool _submitting = false;

  static const _types = ['generic', 'grocery', 'meat', 'restaurant', 'salon'];

  @override
  void dispose() {
    _businessId.dispose();
    _slug.dispose();
    _name.dispose();
    _primaryColor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.ref.read(provisioningProvider.notifier).provision(
            businessId: _businessId.text.trim(),
            slug: _slug.text.trim().toLowerCase(),
            name: _name.text.trim(),
            primaryColor: _primaryColor.text.trim(),
            businessType: _businessType,
            packageId: 'com.${_slug.text.trim().toLowerCase().replaceAll('-', '')}',
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Provision New Tenant'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_businessId, 'Business ID', 'e.g. BIZ001'),
              const SizedBox(height: 12),
              _field(_slug, 'Slug', 'e.g. freshmart', lower: true),
              const SizedBox(height: 12),
              _field(_name, 'App Name', 'e.g. Freshmart'),
              const SizedBox(height: 12),
              _field(_primaryColor, 'Primary Color', '#00B14F'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _businessType = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.primary),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Provision'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool lower = false,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      textCapitalization:
          lower ? TextCapitalization.none : TextCapitalization.words,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null,
    );
  }
}
