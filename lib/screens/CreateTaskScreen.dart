import 'package:basic_utils/basic_utils.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/create_task_screen_widgets/ExampleTasksRoulette.dart';
import 'package:locus/screens/create_task_screen_widgets/SignKeyLottie.dart';
import 'package:locus/screens/create_task_screen_widgets/ViewKeyLottie.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:locus/widgets/TimerWidgetSheet.dart';
import 'package:provider/provider.dart';

import '../widgets/WarningText.dart';

final IN_DURATION = 700.ms;
final IN_DELAY = 80.ms;

class CreateTaskScreen extends StatefulWidget {
  final void Function() onCreated;

  const CreateTaskScreen({
    required this.onCreated,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TimerController _timersController = TimerController();
  final RelayController _relaysController = RelayController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  bool anotherTaskAlreadyExists = false;
  bool showExamples = false;

  TaskCreationProgress? _taskProgress;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      final taskService = context.read<TaskService>();
      final lowerCasedName = _nameController.text.toLowerCase();
      final alreadyExists = taskService.tasks.any((element) => element.name.toLowerCase() == lowerCasedName);

      setState(() {
        anotherTaskAlreadyExists = alreadyExists;
      });
    });
    _timersController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
    _relaysController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    _timersController.dispose();
    _relaysController.dispose();

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  Future<void> createTask(final BuildContext context) async {
    setState(() {
      _taskProgress = TaskCreationProgress.startsSoon;
    });

    final taskService = context.read<TaskService>();

    try {
      final task = await Task.create(
        _nameController.text,
        Duration(minutes: int.parse(_frequencyController.text)),
        _relaysController.relays,
        onProgress: (progress) {
          setState(() {
            _taskProgress = progress;
          });
        },
        timers: _timersController.timers,
      );

      if (!mounted) {
        return;
      }

      await task.startSchedule(startNowIfNextRunIsUnknown: true);
      task.publishCurrentLocationNow();
      taskService.add(task);
      await taskService.save();

      // Calling this explicitly so the text is cleared when leaving the screen
      setState(() {
        _taskProgress = null;
      });

      if (mounted) {
        widget.onCreated();
      }
    } catch (error) {
      setState(() {
        _taskProgress = null;
      });
    }
  }

  Map<TaskCreationProgress, String> getCreationProgressTextMap() {
    final l10n = AppLocalizations.of(context);

    return {
      TaskCreationProgress.creatingSignKeys: l10n.createTask_process_creatingSignKeys,
      TaskCreationProgress.creatingViewKeys: l10n.createTask_process_creatingViewKeys,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.mainScreen_createTask),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
      ),
      material: (_, __) => MaterialScaffoldData(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        if (!isKeyboardVisible)
                          Column(
                            children: <Widget>[
                              const SizedBox(height: SMALL_SPACE),
                              Text(
                                l10n.createTask_title,
                                style: getSubTitleTextStyle(context),
                              ),
                              const SizedBox(height: SMALL_SPACE),
                              Text(
                                l10n.createTask_description,
                                style: getCaptionTextStyle(context),
                              ),
                            ],
                          ),
                        SizedBox(height: isKeyboardVisible ? 0 : LARGE_SPACE),
                        SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    return;
                                  }

                                  setState(() {
                                    showExamples = true;
                                  });
                                },
                                child: PlatformTextFormField(
                                  controller: _nameController,
                                  enabled: _taskProgress == null,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.fields_errors_isEmpty;
                                    }

                                    if (!StringUtils.isAscii(value)) {
                                      return l10n.fields_errors_invalidCharacters;
                                    }

                                    return null;
                                  },
                                  keyboardType: TextInputType.name,
                                  autofillHints: const [AutofillHints.name],
                                  material: (_, __) => MaterialTextFormFieldData(
                                    decoration: InputDecoration(
                                      labelText: l10n.createTask_fields_name_label,
                                      prefixIcon: Icon(context.platformIcons.tag),
                                    ),
                                  ),
                                  cupertino: (_, __) => CupertinoTextFormFieldData(
                                    placeholder: l10n.createTask_fields_name_label,
                                    prefix: Icon(context.platformIcons.tag),
                                  ),
                                )
                                    .animate()
                                    .slide(
                                      duration: IN_DURATION,
                                      curve: Curves.easeOut,
                                      begin: Offset(0, 0.2),
                                    )
                                    .fadeIn(
                                      delay: IN_DELAY,
                                      duration: IN_DURATION,
                                      curve: Curves.easeOut,
                                    ),
                              ),
                              if (showExamples)
                                ExampleTasksRoulette(
                                  disabled: _taskProgress != null,
                                  onSelected: (example) {
                                    FocusManager.instance.primaryFocus?.unfocus();

                                    _nameController.text = example.name;
                                    _frequencyController.text = example.frequency.inMinutes.toString();
                                    _timersController
                                      ..clear()
                                      ..addAll(example.timers);
                                  },
                                ),
                              if (anotherTaskAlreadyExists) ...[
                                const SizedBox(height: MEDIUM_SPACE),
                                WarningText(l10n.createTask_sameTaskNameAlreadyExists),
                              ],
                              const SizedBox(height: MEDIUM_SPACE),
                              PlatformTextFormField(
                                controller: _frequencyController,
                                enabled: _taskProgress == null,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                textAlign: isMaterial(context) ? TextAlign.center : null,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.fields_errors_isEmpty;
                                  }

                                  final frequency = int.parse(value);

                                  if (frequency <= 0) {
                                    return l10n.fields_errors_greaterThan(0);
                                  }

                                  return null;
                                },
                                material: (_, __) => MaterialTextFormFieldData(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.timer),
                                    labelText: l10n.createTask_fields_frequency_label,
                                    prefixText: l10n.createTask_fields_frequency_prefix,
                                    suffixText: l10n.createTask_fields_frequency_suffix,
                                  ),
                                ),
                                cupertino: (_, __) => CupertinoTextFormFieldData(
                                  placeholder: l10n.createTask_fields_frequency_placeholder,
                                  prefix: const Icon(CupertinoIcons.timer),
                                ),
                              )
                                  .animate()
                                  .then(delay: IN_DELAY * 2)
                                  .slide(
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                    begin: Offset(0, 0.2),
                                  )
                                  .fadeIn(
                                    delay: IN_DELAY,
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                  ),
                              const SizedBox(height: MEDIUM_SPACE),
                              Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: SMALL_SPACE,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                direction: Axis.horizontal,
                                children: <Widget>[
                                  PlatformElevatedButton(
                                    material: (_, __) => MaterialElevatedButtonData(
                                      icon: PlatformWidget(
                                        material: (_, __) => const Icon(Icons.dns_rounded),
                                        cupertino: (_, __) => const Icon(CupertinoIcons.list_bullet),
                                      ),
                                    ),
                                    cupertino: (_, __) => CupertinoElevatedButtonData(
                                      padding: getSmallButtonPadding(context),
                                    ),
                                    onPressed: _taskProgress != null
                                        ? null
                                        : () {
                                            showPlatformModalSheet(
                                              context: context,
                                              material: MaterialModalSheetData(
                                                backgroundColor: Colors.transparent,
                                                isScrollControlled: true,
                                                isDismissible: true,
                                              ),
                                              builder: (_) => RelaySelectSheet(
                                                controller: _relaysController,
                                              ),
                                            );
                                          },
                                    child: Text(
                                        l10n.createTask_fields_relays_selectLabel(_relaysController.relays.length)),
                                  )
                                      .animate()
                                      .then(delay: IN_DELAY * 4)
                                      .slide(
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                        begin: Offset(0.2, 0),
                                      )
                                      .fadeIn(
                                        delay: IN_DELAY,
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                      ),
                                  PlatformElevatedButton(
                                    material: (_, __) => MaterialElevatedButtonData(
                                      icon: const Icon(Icons.timer_rounded),
                                    ),
                                    cupertino: (_, __) => CupertinoElevatedButtonData(
                                      padding: getSmallButtonPadding(context),
                                    ),
                                    onPressed: _taskProgress != null
                                        ? null
                                        : () async {
                                            await showPlatformModalSheet(
                                              context: context,
                                              material: MaterialModalSheetData(
                                                backgroundColor: Colors.transparent,
                                                isScrollControlled: true,
                                                isDismissible: true,
                                              ),
                                              builder: (_) => TimerWidgetSheet(
                                                controller: _timersController,
                                              ),
                                            );
                                          },
                                    child: Text(
                                      l10n.createTask_fields_timers_selectLabel(_timersController.timers.length),
                                    ),
                                  )
                                      .animate()
                                      .then(delay: IN_DELAY * 5)
                                      .slide(
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                        begin: Offset(-0.2, 0),
                                      )
                                      .fadeIn(
                                        delay: IN_DELAY,
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: getBodyTextTextStyle(context).copyWith(
                        color: getErrorColor(context),
                      ),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                  ],
                  if (_taskProgress != null) ...[
                    if (_taskProgress == TaskCreationProgress.creatingViewKeys)
                      const Expanded(
                        child: ViewKeyLottie(),
                      ).animate().fadeIn(duration: 1.seconds),
                    if (_taskProgress == TaskCreationProgress.creatingSignKeys)
                      const Expanded(
                        child: SignKeyLottie(),
                      ).animate().fadeIn(duration: 1.seconds),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(
                      getCreationProgressTextMap()[_taskProgress] ?? "",
                      textAlign: TextAlign.center,
                      style: getCaptionTextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                  ],
                  PlatformElevatedButton(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    onPressed: _taskProgress != null
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            if (_relaysController.relays.isEmpty) {
                              setState(() {
                                errorMessage = l10n.createTask_errors_emptyRelays;
                              });
                              return;
                            }

                            createTask(context);
                          },
                    child: Text(
                      l10n.createTask_createLabel,
                      style: TextStyle(
                        fontSize: getActionButtonSize(context),
                      ),
                    ),
                  )
                      .animate()
                      .then(delay: IN_DELAY * 8)
                      .slide(
                        duration: 500.ms,
                        curve: Curves.easeOut,
                        begin: Offset(0, 1.3),
                      )
                      .fadeIn(
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
