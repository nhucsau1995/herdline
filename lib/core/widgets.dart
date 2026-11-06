import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/herd_view.dart';
import 'theme.dart';

final _num = NumberFormat('#,##0');
String liters(num v, {int digits = 0}) => digits == 0 ? '${_num.format(v.round())} L' : '${v.toStringAsFixed(digits)} L';
String shortDate(DateTime d) => DateFormat('d MMM').format(d);
String longDate(DateTime d) => DateFormat('d MMM y').format(d);

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color, this.gradient, this.border});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? C.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: C.shadow,
        border: border == null ? null : Border.all(color: border!),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: box),
    );
  }
}

(Color, Color) toneColors(Tone t) => switch (t) {
      Tone.info => (C.infoFg, C.infoBg),
      Tone.success => (C.okFg, C.okBg),
      Tone.warning => (C.warnFg, C.warnBg),
      Tone.danger => (C.dangerFg, C.dangerBg),
      Tone.neutral => (C.ink2, const Color(0xFFEDF1F7)),
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.tone, {super.key, this.icon});
  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = toneColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
        Text(label, style: T.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class TintChip extends StatelessWidget {
  const TintChip(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => StatusChip(label, Tone.info, icon: icon);
}

class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: C.tint, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 16, color: C.fill),
          const SizedBox(width: 6),
          Text('Offline - saved on device', style: T.caption.copyWith(color: C.fill)),
        ]),
      );
}

class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: selected ? C.fill : C.surface,
          shape: StadiumBorder(side: BorderSide(color: selected ? C.fill : C.border)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(widthFactor: 1, child: Text(label, style: T.label.copyWith(color: selected ? Colors.white : C.ink2))),
              ),
            ),
          ),
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.icon, required this.onPressed, this.expand = true});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return C.fill.withValues(alpha: 0.4);
          if (s.contains(WidgetState.pressed)) return C.pressed;
          return C.fill;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        textStyle: WidgetStatePropertyAll(T.label.copyWith(fontWeight: FontWeight.w600)),
        elevation: const WidgetStatePropertyAll(0),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(label),
      ]),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.icon, required this.onPressed});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: const StadiumBorder(),
            side: const BorderSide(color: C.fill, width: 1.5),
            foregroundColor: C.fill,
            textStyle: T.label.copyWith(fontWeight: FontWeight.w600),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ]),
        ),
      );
}

class FloatingPill extends StatelessWidget {
  const FloatingPill({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), boxShadow: const [
          BoxShadow(color: Color(0x331B65DA), blurRadius: 16, offset: Offset(0, 6)),
        ]),
        child: PrimaryButton(label: label, icon: Icons.add_rounded, onPressed: onPressed, expand: false),
      );
}

/// Local photo from assets/images (all imagery is bundled, nothing is loaded from the network).
class Photo extends StatelessWidget {
  const Photo(this.name, {super.key, this.size = 56, this.radius = 16, this.width, this.height});
  final String? name;
  final double size;
  final double radius;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size, h = height ?? size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: name == null
          ? Container(width: w, height: h, color: C.tint, child: const Icon(Icons.pets_outlined, color: C.fill))
          : Image.asset('assets/images/$name.jpg', width: w, height: h, fit: BoxFit.cover),
    );
  }
}

class IconPill extends StatelessWidget {
  const IconPill(this.icon, {super.key, this.color = C.fill, this.bg = C.tint, this.size = 40});
  final IconData icon;
  final Color color, bg;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [Expanded(child: Text(title, style: T.title)), ?trailing]),
      );
}

/// Top bar for detail and form screens: back/close, title + caption, optional actions.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.title, this.caption, this.close = false, this.actions = const []});
  final String title;
  final String? caption;
  final bool close;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(children: [
          IconButton(
            key: const Key('back'),
            tooltip: close ? 'Close' : 'Back',
            icon: Icon(close ? Icons.close_rounded : Icons.arrow_back_rounded, color: C.ink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (caption != null) Text(caption!, style: T.caption),
            ]),
          ),
          ...actions,
        ]),
      );
}

/// Top bar for the five tab screens.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.caption, this.trailing});
  final String title;
  final String? caption;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(children: [
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(title, style: T.title),
              if (caption != null) ...[const SizedBox(width: 8), Text(caption!, style: T.caption)],
            ]),
          ),
          ?trailing,
        ]),
      );
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.k, this.v, {super.key, this.vColor});
  final String k, v;
  final Color? vColor;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(child: Text(k, style: T.label.copyWith(color: C.ink2))),
          Text(v, style: T.label.copyWith(color: vColor ?? C.ink, fontWeight: FontWeight.w600)),
        ]),
      );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text.rich(TextSpan(text: text, style: T.caption, children: [
          if (required) TextSpan(text: ' *', style: T.caption.copyWith(color: C.dangerFg)),
        ])),
      );
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));

/// Runs a write and reports a failure instead of crashing the screen.
Future<bool> guarded(BuildContext context, Future<void> Function() op, {String? ok}) async {
  try {
    await op();
    if (ok != null && context.mounted) toast(context, ok);
    return true;
  } catch (e) {
    if (context.mounted) toast(context, 'Could not save: $e');
    return false;
  }
}

class NoAccess extends StatelessWidget {
  const NoAccess(this.what, {super.key});
  final String what;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: C.ink3),
          const SizedBox(width: 6),
          Expanded(child: Text('Your role can view but not change $what.', style: T.caption)),
        ]),
      );
}
