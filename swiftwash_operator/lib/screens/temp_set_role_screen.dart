import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TempSetRoleScreen extends StatefulWidget {
  const TempSetRoleScreen({super.key});

  @override
  _TempSetRoleScreenState createState() => _TempSetRoleScreenState();
}

class _TempSetRoleScreenState extends State<TempSetRoleScreen> {
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  String _message = '';

  Future<void> _createUserAndSetRole() async {
    try {
      // Create the user
      final HttpsCallable createUserCallable = FirebaseFunctions.instance.httpsCallable('createUser');
      final createUserResult = await createUserCallable.call(<String, dynamic>{
        'email': _emailController.text.trim(),
        'password': 'FoundersOffice',
      });

      if (createUserResult.data['error'] != null) {
        setState(() {
          _message = createUserResult.data['error'];
        });
        return;
      }

      // Set the user's role
      final HttpsCallable setRoleCallable = FirebaseFunctions.instance.httpsCallable('setUserRole');
      final setRoleResult = await setRoleCallable.call(<String, dynamic>{
        'email': _emailController.text.trim(),
        'role': _roleController.text.trim(),
      });

      setState(() {
        _message = setRoleResult.data['message'] ?? setRoleResult.data['error'];
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set User Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createUserAndSetRole,
              child: const Text('Create User and Set Role'),
            ),
            const SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
