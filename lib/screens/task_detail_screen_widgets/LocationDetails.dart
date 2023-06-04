import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/utils/show_success_message.dart';
import 'package:locus/utils/theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import '../../widgets/PlatformListTile.dart';

class LocationDetails extends StatefulWidget {
  final LocationPointService location;
  final bool isPreview;

  const LocationDetails({
    required this.location,
    required this.isPreview,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationDetails> createState() => _LocationDetailsState();
}

class _LocationDetailsState extends State<LocationDetails> {
  String address = "";
  bool isOpened = false;

  String get formattedString =>
      "${widget.location.latitude.toStringAsFixed(5)}, ${widget.location
          .longitude.toStringAsFixed(5)}";

  Map<BatteryState?, String> getBatteryStateTextMap() {
    final l10n = AppLocalizations.of(context);

    return {
      BatteryState.charging:
      l10n.taskDetails_locationDetails_batteryState_charging,
      BatteryState.discharging:
      l10n.taskDetails_locationDetails_batteryState_discharging,
      BatteryState.full: l10n.taskDetails_locationDetails_batteryState_full,
      BatteryState.unknown:
      l10n.taskDetails_locationDetails_batteryState_unknown,
      null: l10n.taskDetails_locationDetails_batteryState_unknown,
    };
  }

  IconData getIconForBatteryLevel(final double? level) {
    if (isCupertino(context)) {
      if (level == null) {
        return CupertinoIcons.battery_full;
      }

      if (level > 0.9) {
        return CupertinoIcons.battery_100;
      } else if (level > 0.25) {
        return CupertinoIcons.battery_25;
      } else {
        return CupertinoIcons.battery_0;
      }
    }

    if (level == null) {
      return Icons.battery_unknown_rounded;
    }

    if (level == 1) {
      return Icons.battery_full;
    } else if (level >= .83) {
      return Icons.battery_6_bar_rounded;
    } else if (level >= .67) {
      return Icons.battery_5_bar_rounded;
    } else if (level >= .5) {
      return Icons.battery_4_bar_rounded;
    } else if (level >= .33) {
      return Icons.battery_3_bar_rounded;
    } else if (level >= .17) {
      return Icons.battery_2_bar_rounded;
    } else if (level >= .05) {
      return Icons.battery_1_bar_rounded;
    } else {
      return Icons.battery_0_bar_rounded;
    }
  }

  void fetchAddress() async {
    if (this.address.isNotEmpty) {
      return;
    }

    final settings = context.read<SettingsService>();

    final address = await settings.getAddress(
        widget.location.latitude, widget.location.longitude);

    setState(() {
      this.address = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PlatformTextButton(
          onPressed: widget.isPreview
              ? null
              : () {
            fetchAddress();

            setState(() {
              isOpened = !isOpened;
            });
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.taskDetails_locationDetails_createdAt_value(
                widget.location.createdAt,
              ),
              textAlign: TextAlign.start,
              style: getBodyTextTextStyle(context),
            ),
          ),
        ),
        isOpened
            ? Container(
          decoration: BoxDecoration(
            color: platformThemeData(
              context,
              material: (data) => data.scaffoldBackgroundColor,
              cupertino: (data) => data.scaffoldBackgroundColor,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(MEDIUM_SPACE),
            ),
          ),
          child: Column(
            children: <Widget>[
              PlatformListTile(
                title: Text(
                  formattedString,
                ),
                leading: const Icon(Icons.my_location),
                trailing: const SizedBox.shrink(),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: formattedString,
                    ),
                  );

                  showSuccessMessage(context, l10n.textCopiedToClipboard);
                },
              ),
              PlatformListTile(
                title: Text(
                  address,
                ),
                leading: Icon(context.platformIcons.location),
                trailing: const SizedBox.shrink(),
                onTap: () {
                  if (address.isEmpty) {
                    return;
                  }

                  Clipboard.setData(
                    ClipboardData(
                      text: address,
                    ),
                  );

                  showSuccessMessage(context, l10n.textCopiedToClipboard);
                },
              ),
              PlatformListTile(
                title: Text(
                  l10n.taskDetails_locationDetails_accuracy_value(
                    widget.location.accuracy.round(),
                  ),
                ),
                leading: const Icon(MdiIcons.circleDouble),
                subtitle:
                Text(l10n.taskDetails_locationDetails_accuracy_label),
                trailing: const SizedBox.shrink(),
              ),
              PlatformListTile(
                title: Text(
                  widget.location.batteryLevel == null
                      ? l10n.unknownValue
                      : l10n.taskDetails_locationDetails_battery_value(
                    (widget.location.batteryLevel! * 100).floor(),
                  ),
                ),
                subtitle:
                Text(l10n.taskDetails_locationDetails_battery_label),
                leading: Icon(
                  getIconForBatteryLevel(
                    widget.location.batteryLevel,
                  ),
                ),
                trailing: const SizedBox.shrink(),
              ),
              PlatformListTile(
                title: Text(
                  getBatteryStateTextMap()[widget.location.batteryState]!,
                ),
                subtitle: Text(
                  l10n.taskDetails_locationDetails_batteryState_label,
                ),
                leading: const Icon(Icons.cable_rounded),
                trailing: const SizedBox.shrink(),
              ),
              PlatformListTile(
                title: Text(
                  widget.location.speed == null
                      ? l10n.unknownValue
                      : l10n.taskDetails_locationDetails_speed_value(
                    widget.location.speed!.toInt().abs(),
                  ),
                ),
                subtitle: Text(
                  l10n.taskDetails_locationDetails_speed_label,
                ),
                leading: PlatformWidget(
                  material: (_, __) => const Icon(Icons.speed),
                  cupertino: (_, __) =>
                  const Icon(CupertinoIcons.speedometer),
                ),
                trailing: const SizedBox.shrink(),
              ),
              PlatformListTile(
                title: Text(
                  widget.location.altitude == null
                      ? l10n.unknownValue
                      : l10n.taskDetails_locationDetails_altitude_value(
                    widget.location.altitude!.toInt().abs(),
                  ),
                ),
                subtitle:
                Text(l10n.taskDetails_locationDetails_altitude_label),
                leading: PlatformWidget(
                  material: (_, __) => const Icon(Icons.height_rounded),
                  cupertino: (_, __) => const Icon(CupertinoIcons.alt),
                ),
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
        )
            : const SizedBox.shrink(),
      ],
    );
  }
}
