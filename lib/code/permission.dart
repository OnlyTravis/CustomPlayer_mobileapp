import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermission(Permission permission) async {
  if (await permission.isGranted) return true;
  if (await permission.request() == PermissionStatus.granted) return true;
  return false;
}