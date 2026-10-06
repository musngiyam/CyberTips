import 'package:flutter/material.dart';

/// 1. HACK NPC SCREEN: Used for cracking Wi-Fi passwords via Kali Linux penetration tools.
class HackTerminalScreen extends StatefulWidget {
  final int characterIndex;
  const HackTerminalScreen({super.key, required this.characterIndex});

  @override
  State<HackTerminalScreen> createState() => _HackTerminalScreenState();
}

class _HackTerminalScreenState extends State<HackTerminalScreen> {
  String? selectedWifiName;
  String? selectedIp;
  String? crackedPassword;
  List<String> userSequence = [];
  final List<String> correctSequence = ["nmap", "wireshark", "aircrack-ng", "hydra"];

  final List<String> terminalLogs = [
    "Connected to Kali Linux Penetration Testing Environment...",
    "Select a target Wi-Fi network below to crack its password."
  ];

  final List<Map<String, String>> wifiTargets = [
    {"name": "Campus_Guest", "ip": "192.168.1.1", "pass": "guest123"},
    {"name": "Lab_Secure_WiFi", "ip": "192.168.1.50", "pass": "secure2026!"},
    {"name": "Admin_Hidden_AP", "ip": "10.0.0.254", "pass": "rootadmin#99"},
  ];

  void _executeStep(String toolName) {
    if (selectedWifiName == null) return;

    setState(() {
      userSequence.add(toolName);
      if (toolName == "nmap") {
        terminalLogs.addAll([
          "kali# nmap -sn $selectedIp",
          "Starting Nmap 7.94 ( https://nmap.org )",
          "Nmap scan report for $selectedWifiName ($selectedIp)",
          "Host is up (0.0019s latency).",
          "-> Host discovered & active."
        ]);
      } else if (toolName == "wireshark") {
        terminalLogs.addAll([
          "kali# wireshark -i wlan0 -Y \"eapol\"",
          "Capturing traffic on interface wlan0...",
          "Association request received from target AP.",
          "Captured 4-way handshake (EAPOL Key frames 1 to 4).",
          "-> Handshake saved to handshake.cap."
        ]);
      } else if (toolName == "aircrack-ng") {
        terminalLogs.addAll([
          "kali# aircrack-ng -w /usr/share/wordlists/rockyou.txt handshake.cap",
          "Reading packets, please wait...",
          "Phase 1: Checking for WPA/WPA2 handshakes...",
          "Phase 2: Brute-forcing pre-shared key...",
          "-> Key successfully analyzed and extracted."
        ]);
      } else if (toolName == "hydra") {
        terminalLogs.addAll([
          "kali# hydra -l admin -P passlist.txt $selectedIp ssh",
          "Hydra v9.5 (c) by van Hauser / THC - https://thc.org",
          "[DATA] 1 target, 1 login, 1000 passwords",
          "[STATUS] Attack started, running parallel threads...",
          "-> Brute-force complete. Access credentials verified."
        ]);
      }
    });
  }

  void _validateSequence() {
    bool isCorrect = true;
    if (userSequence.length != correctSequence.length) {
      isCorrect = false;
    } else {
      for (int i = 0; i < correctSequence.length; i++) {
        if (userSequence[i] != correctSequence[i]) {
          isCorrect = false;
          break;
        }
      }
    }

    final targetWifi = wifiTargets.firstWhere((wifi) => wifi["name"] == selectedWifiName);
    crackedPassword = targetWifi["pass"];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E281A),
        title: Text(
          isCorrect ? "PASSWORD CRACKED!" : "ACCESS DENIED",
          style: TextStyle(
            color: isCorrect ? const Color(0xFF81C784) : const Color(0xFFFFCDD2),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isCorrect
              ? "Successfully cracked $selectedWifiName!\n\nRetrieved Password: '$crackedPassword'\n\nYou can now go to the Wi-Fi NPC to type this password and connect."
              : "Incorrect tool sequence! Network IDS blocked your intrusion attempt.",
          style: const TextStyle(color: Color(0xFFCFD8DC), fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isCorrect) {
                Navigator.pop(context); // Return to game map after cracking
              } else {
                setState(() {
                  userSequence.clear();
                });
              }
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFF9C4))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E281A),
        title: const Text("Hack NPC: Password Cracking Console", style: TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Target Wi-Fi Node to Crack:", style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: wifiTargets.map((wifi) {
                bool isSelected = selectedWifiName == wifi["name"];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF324C2C) : const Color(0xFF131A11),
                        side: BorderSide(color: isSelected ? const Color(0xFF81C784) : Colors.white24),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedWifiName = wifi["name"];
                          selectedIp = wifi["ip"];
                          terminalLogs.add("Target locked for cracking: $selectedWifiName [$selectedIp]");
                        });
                      },
                      child: Text("${wifi['name']}\n(${wifi['ip']})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text("Step-by-Step Tool Selection (Nmap -> Wireshark -> Aircrack-ng -> Hydra):", style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: selectedWifiName == null ? null : () => _executeStep("nmap"), child: const Text("1. nmap")),
                ElevatedButton(onPressed: selectedWifiName == null ? null : () => _executeStep("wireshark"), child: const Text("2. wireshark")),
                ElevatedButton(onPressed: selectedWifiName == null ? null : () => _executeStep("aircrack-ng"), child: const Text("3. aircrack-ng")),
                ElevatedButton(onPressed: selectedWifiName == null ? null : () => _executeStep("hydra"), child: const Text("4. hydra")),
              ],
            ),
            const SizedBox(height: 12),
            Text("Current Execution Queue: ${userSequence.join(" -> ")}", style: const TextStyle(color: Color(0xFFFFF9C4), fontFamily: 'monospace', fontSize: 11)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A11),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF324C2C)),
                ),
                child: ListView.builder(
                  itemCount: terminalLogs.length,
                  itemBuilder: (context, index) => Text(
                    terminalLogs[index],
                    style: const TextStyle(color: Color(0xFF00FF66), fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => userSequence.clear()),
                  child: const Text("Reset Sequence", style: TextStyle(color: Color(0xFFFFCDD2))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: userSequence.isEmpty || selectedWifiName == null ? null : _validateSequence,
                  child: const Text("Run Exploit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. WIFI NPC DIALOG: Directly shows the 3 Wi-Fi networks with names and IPs when interacting with the Wi-Fi NPC.
class WifiNpcDialog extends StatelessWidget {
  const WifiNpcDialog({super.key});

  final List<Map<String, String>> wifiTargets = const [
    {"name": "Campus_Guest", "ip": "192.168.1.1", "pass": "guest123"},
    {"name": "Lab_Secure_WiFi", "ip": "192.168.1.50", "pass": "secure2026!"},
    {"name": "Admin_Hidden_AP", "ip": "10.0.0.254", "pass": "rootadmin#99"},
  ];

  void _promptPassword(BuildContext context, Map<String, String> wifi) {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E281A),
        title: Text(
          "Connect to ${wifi['name']}",
          style: const TextStyle(color: Color(0xFF81C784), fontFamily: 'monospace', fontSize: 14),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("IP Address: ${wifi['ip']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            const Text("Enter Password (from Hack NPC):", style: TextStyle(color: Color(0xFF8FBC8F), fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Password...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF131A11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFFFFCDD2))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pop(context);
              bool isCorrect = passController.text == wifi["pass"];

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E281A),
                  title: Text(
                    isCorrect ? "CONNECTED SUCCESSFULLY" : "CONNECTION FAILED",
                    style: TextStyle(
                      color: isCorrect ? const Color(0xFF81C784) : const Color(0xFFFFCDD2),
                      fontFamily: 'monospace',
                    ),
                  ),
                  content: Text(
                    isCorrect
                        ? "Successfully connected to ${wifi['name']} [${wifi['ip']}]."
                        : "Incorrect password! Use the Hack NPC terminal first to crack it.",
                    style: const TextStyle(color: Color(0xFFCFD8DC), fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isCorrect) Navigator.pop(context); // Close dialog on success
                      },
                      child: const Text("OK", style: TextStyle(color: Color(0xFFFFF9C4))),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Connect", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF263222),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF81C784), width: 1.5),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wi-Fi Node Guardian",
              style: TextStyle(
                color: Color(0xFF81C784),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select a network node below to enter your cracked password:",
              style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...wifiTargets.map((wifi) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131A11),
                    side: const BorderSide(color: Color(0xFF81C784)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _promptPassword(context, wifi),
                  child: Text(
                    "${wifi['name']} (${wifi['ip']})",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFFFFCDD2))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}