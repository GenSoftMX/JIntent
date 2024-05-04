import 'package:flutter/material.dart';
import 'package:jintent/commons.dart';
import 'package:jintent/jprogress_dialog_manager_controller.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

///
/// class for managing the display and hiding of a progress dialog.
///
class ProgressDialogManager
    with JCommonsMixin
    implements JProgressDialogManagerController {
  late final ProgressDialog _progressDialog;

  ProgressDialogManager() {
    _progressDialog = ProgressDialog(context: context);
  }

  @override
  Future<void> show({String? msg}) async => _progressDialog.show(
      msg: msg ?? "wait",
      barrierColor: Colors.black.withOpacity(0.4),
      elevation: 10.0,
      borderRadius: 10.0);

  @override
  Future<void> hide() async => _progressDialog.close();
}
