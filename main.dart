import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const CasinoMasterApp());
}

class CasinoMasterApp extends StatelessWidget {
  const CasinoMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Royal Teen Patti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const SplashScreen(),
    );
  }
}

// ----------------- GLOBAL USER STATE -----------------
class UserData {
  static String name = "Player";
  static String avatar = "😎";
  static double depositBalance = 500.0;
  static double winningBalance = 1000.0;

  static double get totalBalance => depositBalance + winningBalance;

  static void addDeposit(double amount) {
    depositBalance += amount;
  }

  static bool deductBet(double amount) {
    if (totalBalance < amount) return false;
    if (depositBalance >= amount) {
      depositBalance -= amount;
    } else {
      double rem = amount - depositBalance;
      depositBalance = 0;
      winningBalance -= rem;
    }
    return true;
  }

  static void addWinnings(double amount) {
    winningBalance += amount;
  }

  static bool withdraw(double amount) {
    if (winningBalance >= amount) {
      winningBalance -= amount;
      return true;
    }
    return false;
  }
}

// ----------------- 1. SPLASH SCREEN -----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainContentAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Colors.amber, Colors.deepOrange]),
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 30)],
              ),
              child: const Icon(Icons.casino, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "ROYAL TEEN PATTI",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text("Loading Table...", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

// ----------------- 2. LOGIN / REGISTER SCREEN -----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Anand");
  String _selectedAvatar = "🦁";
  final List<String> avatars = ["🦁", "😎", "👑", "🚀", "🐯", "💎"];

  void _login() {
    if (_nameController.text.trim().isNotEmpty) {
      UserData.name = _nameController.text.trim();
      UserData.avatar = _selectedAvatar;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLobbyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainContentAxisAlignment.center,
            children: [
              const Text("Welcome Player", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: avatars.map((a) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = a),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedAvatar == a ? Colors.amber : Colors.grey[800],
                        border: Border.all(color: Colors.amberAccent, width: _selectedAvatar == a ? 3 : 1),
                      ),
                      child: Text(a, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Your Nickname",
                  prefixIcon: const Icon(Icons.person, color: Colors.amber),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Enter Lobby", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- 3. MAIN LOBBY SCREEN -----------------
class MainLobbyScreen extends StatefulWidget {
  const MainLobbyScreen({super.key});

  @override
  State<MainLobbyScreen> createState() => _MainLobbyScreenState();
}

class _MainLobbyScreenState extends State<MainLobbyScreen> {
  void _openWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletScreen()),
    ).then((_) => setState(() {}));
  }

  void _claimDailyBonus() {
    setState(() {
      UserData.addDeposit(200);
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("🎉 Daily Reward!", style: TextStyle(color: Colors.amber)),
        content: const Text("Aapke wallet me ₹200 bonus chips add kar diye gaye hain!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.amber, child: Text(UserData.avatar, style: const TextStyle(fontSize: 20))),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(UserData.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("₹ ${UserData.totalBalance.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.amber),
            tooltip: "Daily Bonus",
            onPressed: _claimDailyBonus,
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.amber),
            tooltip: "Wallet",
            onPressed: _openWallet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Royal Casino", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Total Chips: ₹${UserData.totalBalance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amberAccent)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _openWallet,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    child: const Text("+ Add Cash"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text("Popular Games", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),

            // Game 1: Teen Patti
            _buildGameCard(
              title: "Realistic Teen Patti",
              subtitle: "5 Players Live Table | Classic Rules",
              icon: Icons.style,
              color: Colors.redAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeenPattiGameScreen())).then((_) => setState(() {}));
              },
            ),

            // Game 2: Dragon vs Tiger
            _buildGameCard(
              title: "Dragon vs Tiger",
              subtitle: "Instant 1 Card Showdown | Fast Win",
              icon: Icons.flash_on,
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DragonTigerGameScreen())).then((_) => setState(() {}));
              },
            ),

            // Game 3: Andar Bahar
            _buildGameCard(
              title: "Andar Bahar",
              subtitle: "Joker Match Game | 50-50 Chance",
              icon: Icons.swap_horiz,
              color: Colors.teal,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AndarBaharGameScreen())).then((_) => setState(() {}));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill, color: Colors.amber, size: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- 4. WALLET & PAYMENT SCREEN -----------------
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController(text: "500");
  final TextEditingController _withdrawAmount = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _addMoney(double amount) {
    setState(() {
      UserData.addDeposit(amount);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("₹$amount successfully added via UPI!"), backgroundColor: Colors.green),
    );
  }

  void _withdrawMoney() {
    double amt = double.tryParse(_withdrawAmount.text.trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valid amount dalein!"), backgroundColor: Colors.red));
      return;
    }
    if (_upiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("UPI ID ya Bank detail dalein!"), backgroundColor: Colors.red));
      return;
    }
    if (UserData.winningBalance < amt) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Winning balance insufficient hai!"), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      UserData.withdraw(amt);
    });
    _withdrawAmount.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("✅ Withdrawal Placed", style: TextStyle(color: Colors.greenAccent)),
        content: Text("₹$amt aapke diye gaye UPI account me transfer kar diya jayega."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.amber)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [Tab(text: "Add Cash"), Tab(text: "Withdraw")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Add Cash
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Deposit Balance: ₹${UserData.depositBalance.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, color: Colors.amberAccent)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  children: [100, 500, 1000, 2000].map((val) {
                    return ElevatedButton(
                      onPressed: () => _addMoney(val.toDouble()),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                      child: Text("+ ₹$val", style: const TextStyle(color: Colors.amber)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Custom Amount (₹)", filled: true, fillColor: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    double amt = double.tryParse(_amountController.text.trim()) ?? 0;
                    if (amt > 0) _addMoney(amt);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Pay via UPI / GPay / PhonePe", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Tab 2: Withdraw
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Winnings Balance: ₹${UserData.winningBalance.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, color: Colors.greenAccent)),
                const SizedBox(height: 5),
                const Text("Sirf Winning balance withdraw kiya ja sakta hai.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _withdrawAmount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Withdrawal Amount (₹)", filled: true, fillColor: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _upiController,
                  decoration: const InputDecoration(labelText: "UPI ID / Account Number", filled: true, fillColor: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _withdrawMoney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Request Instant Withdrawal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- 5. REALISTIC TEEN PATTI SCREEN -----------------
class TeenPattiGameScreen extends StatefulWidget {
  const TeenPattiGameScreen({super.key});

  @override
  State<TeenPattiGameScreen> createState() => _TeenPattiGameScreenState();
}

class PlayerModel {
  final String name;
  final String avatar;
  double balance;
  bool isBot;
  bool isPacked;
  bool isSeen;
  List<String> cards;

  PlayerModel({
    required this.name,
    required this.avatar,
    required this.balance,
    required this.isBot,
    this.isPacked = false,
    this.isSeen = false,
    required this.cards,
  });
}

class _TeenPattiGameScreenState extends State<TeenPattiGameScreen> {
  double potAmount = 0;
  double currentChaal = 20;
  int turnIndex = 0; // 0 is User, 1..4 are Bots
  String gameStatus = "Game Started! Chaal chaliye.";
  bool gameOver = false;

  late List<PlayerModel> players;

  final List<Strin
