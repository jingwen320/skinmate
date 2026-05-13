import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SkinProgressPage extends StatefulWidget {
  @override
  _SkinProgressPageState createState() => _SkinProgressPageState();
}

class _SkinProgressPageState extends State<SkinProgressPage> {
  List progress = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  void fetchProgress() async {
    try {
      var res = await ApiService.getSkinProgress("1"); // Replace 1 with userID
      setState(() {
        progress = res['scans'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    if (progress.isEmpty) return Center(child: Text("No scans yet"));

    return ListView.builder(
      itemCount: progress.length,
      itemBuilder: (context, index) {
        var scan = progress[index];
        return ListTile(
          leading: Image.network(scan['image'], width: 50, height: 50, fit: BoxFit.cover),
          title: Text(scan['date']),
          subtitle: Text("Skin Type: ${scan['skin_type']}"),
        );
      },
    );
  }
}