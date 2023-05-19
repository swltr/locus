import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:map_launcher/map_launcher.dart';

import 'PlatformListTile.dart';

const ICON_SIZE = 36.0;

class OpenInMaps extends StatefulWidget {
  final Coords destination;

  const OpenInMaps({
    required this.destination,
    Key? key,
  }) : super(key: key);

  @override
  State<OpenInMaps> createState() => _OpenInMapsState();
}

class _OpenInMapsState extends State<OpenInMaps> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.openInMaps_title,
                  style: getTitle2TextStyle(context),
                ),
                const SizedBox(height: SMALL_SPACE),
                Text(l10n.openInMaps_description),
                const SizedBox(height: MEDIUM_SPACE),
                FutureBuilder<List<AvailableMap>>(
                  future: MapLauncher.installedMaps,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final map = snapshot.data![index];

                            return PlatformListTile(
                              title: Text(map.mapName),
                              onTap: () {
                                map.showDirections(
                                  destination: widget.destination,
                                );
                                Navigator.pop(context);
                              },
                              leading: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(SMALL_SPACE),
                                child: SvgPicture.asset(
                                  map.icon,
                                  height: ICON_SIZE,
                                  width: ICON_SIZE,
                                ),
                              ),
                              trailing:
                                  Icon(context.platformIcons.rightChevron),
                            );
                          },
                        );
                      }

                      return Column(
                        children: <Widget>[
                          Text(l10n.unknownError),
                          const SizedBox(height: SMALL_SPACE),
                          PlatformListTile(
                            title: Text(
                              "Lat: ${widget.destination.latitude}, Long: ${widget.destination.longitude}",
                            ),
                            leading: PlatformIconButton(
                              icon: PlatformWidget(
                                material: (_, __) => const Icon(Icons.copy),
                                cupertino: (_, __) =>
                                    const Icon(CupertinoIcons.doc_on_clipboard),
                              ),
                              onPressed: () {
                                // Copy to clipboard
                                Clipboard.setData(
                                  ClipboardData(
                                    text:
                                        "${widget.destination.latitude}, ${widget.destination.longitude}",
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
                const SizedBox(height: LARGE_SPACE),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
