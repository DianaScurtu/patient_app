import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lab2_patient_app/dto/patient.dart';

import 'login_page.dart';

class PatientsScreen extends StatefulWidget {
  final String? email;

  const PatientsScreen({super.key, required this.email});

  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  Future<List<Patient>> fetchPatients() async {
    final url = Uri.parse(
      "https://portal.acs.pub.ro/ehealth/unsecured/patients",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      List<dynamic> entries = jsonData['entry'] ?? [];
      return entries.map((entry) => Patient.fromJson(entry)).toList();
    } else {
      throw Exception("Failed to load patients");
    }
  }

  Future<void> _showEditDialog(Patient patient) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController controller = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Patient ${patient.id}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Change Name"),
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Please enter some text'
                          : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  debugPrint("Updated Value: ${controller.text}");
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Hello ${widget.email}'),
            const Text('Patients List'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Patient>>(
        future: fetchPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No patients found"));
          }

          final patients = snapshot.data!;
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [const Icon(Icons.person), Text("${patient.id}")],
                  ),
                  title: Text(patient.fullName),
                  subtitle: Text("Email: ${patient.email}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(patient),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
