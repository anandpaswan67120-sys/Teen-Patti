import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const TeenPattiApp());

class TeenPattiApp extends StatelessWidget {
  const TeenPattiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Teen Patti',
        theme: ThemeData.dark(useMaterial3: true),
        home: const GameScreen(),
      );
}

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class PCard {
  final int rank; // 2..14 (14 = Ace)
  final int suit; // 0 spade, 1 heart, 2 club, 3 diamond
  const PCard(this.rank, this.suit);
  String get rankText => const {11: 'J', 12: 'Q', 13: 'K', 14: 'A'}[rank] ?? '$rank';
  String get suitText => const ['♠', '♥', '♣', '♦'][suit];
  bool get isRed => suit == 1 || suit == 3;
}

class HandResult {
  final int category; // 6 trail, 5 pure seq, 4 seq, 3 flush, 2 pair, 1 high
  final int score;
  final String name;
  const HandResult(this.category, this.score, this.name);
}

/// Teen Patti hand evaluation. A higher score always means a better hand.
HandResult evaluate(List<PCard> h) {
  final r = h.map((c) => c.rank).toList()..sort((a, b) => b - a);
  final flush = h.every((c) => c.suit == h[0].suit);
  var seq = false;
  var seqHigh = r[0];
  if (r[0] - r[1] == 1 && r[1] - r[2] == 1) {
    seq = true;
  } else if (r[0] == 14 && r[1] == 3 && r[2] == 2) {
    seq = true; // A-2-3 is the lowest sequence
    seqHigh = 3;
  }
  final tb = r[0] * 225 + r[1] * 15 + r[2];
  if (r[0] == r[1] && r[1] == r[2]) return HandResult(6, 6000000 + r[0], 'Trail');
  if (seq && flush) return HandResult(5, 5000000 + seqHigh, 'Pure Sequence');
  if (seq) return HandResult(4, 4000000 + seqHigh, 'Sequence');
  if (flush) return HandResult(3, 3000000 + tb, 'Color');
  if (r[0] == r[1] || r[1] == r[2]) {
    final kicker = r[0] == r[1] ? r[2] : r[0];
    return HandResult(2, 2000000 + r[1] * 15 + kicker, 'Pair');
  }
  return HandResult(1, 1000000 + tb, 'High Card');
}

class Player {
  String name;
  final bool isBot;
  Color color;
  int chips;
  List<PCard> cards = [];
  bool seen = false;
  bool packed = false;
  int moves = 0;
  Player(this.name, this.isBot, this.color, this.chips);
}

// ---------------------------------------------------------------------------
// GAME SCREEN
// ---------------------------------------------------------------------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int boot = 50;
  static const int maxStake = 1600;
  static const List<Alignment> _seat = [
    Alignment(0, 0.9),
    Alignment(-0.95, 0.1),
    Alignment(-0.5, -0.9),
    Alignment(0.5, -0.9),
    Alignment(0.95, 0.1),
  ];

  final Random rng = Random();
  final List<Player> players = [
    Player('आप', false, Colors.teal, 5000),
    Player('Rohit', true, Colors.deepOrange, 5000),
    Player('Sneha', true, Colors.pink, 5000),
    Player('Tanya', true, Colors.purple, 5000),
    Player('Rahul', true, Colors.blueGrey, 5000),
  ];

  List<PCard> deck = [];
  int pot = 0;
  int stake = boot;
  int turn = 0;
  int thinking = -1;
  int _starter = 0;
  bool gameOver = false;
  bool revealAll = false;
  bool showChip = false;
  int chipAmt = 0;
  Alignment chipAlign = Alignment.center;
  String message = '';

  @override
  void initState() {
    super.initState();
    _deal();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTurn());
  }

  // ---------------- core helpers ----------------

  List<Player> get _active => players.where((p) => !p.packed).toList();

  int _nextActive(int from) {
    var i = (from + 1) % players.length;
    while (players[i].packed) {
      i = (i + 1) % players.length;
    }
    return i;
  }

  Player _prevActive(Player p) {
    var i = (players.indexOf(p) - 1 + players.length) % players.length;
    while (players[i].packed) {
      i = (i - 1 + players.length) % players.length;
    }
    return players[i];
  }

  int _cost(Player p) => p.seen ? stake * 2 : stake;

  void _pay(Player p, int cost) {
    final c = min(cost, p.chips);
    p.chips -= c;
    pot += c;
  }

  static const List<String> _namePool = [
    'Rohit', 'Sneha', 'Tanya', 'Rahul', 'Amit', 'Priya', 'Vikas', 'Pooja',
    'Sandeep', 'Neha', 'Rajesh', 'Kavita', 'Manoj', 'Anjali', 'Suresh', 'Ritu',
    'Deepak', 'Simran', 'Arjun', 'Komal', 'Gaurav', 'Meena', 'Sunil', 'Divya',
    'Ajay', 'Pallavi', 'Vishal', 'Nisha', 'Karan', 'Swati', 'Mukesh', 'Isha',
    'Pankaj', 'Jyoti', 'Ravi', 'Sonam', 'Nitin', 'Shweta', 'Ashok', 'Payal',
  ];
  static const List<Color> _colorPool = [
    Colors.deepOrange, Colors.pink, Colors.purple, Colors.blueGrey,
    Colors.indigo, Colors.brown, Colors.cyan, Colors.deepPurple,
    Colors.green, Colors.red, Colors.orange, Colors.blue,
  ];
  List<String> _lastNames = [];

  /// Gives the 4 bots brand new names every game (no repeat of the last game)
  void _assignBotNames() {
    final pool = _namePool.where((n) => !_lastNames.contains(n)).toList()..shuffle(rng);
    final colors = [..._colorPool]..shuffle(rng);
    for (int i = 1; i < players.length; i++) {
      players[i].name = pool[i - 1];
      players[i].color = colors[i - 1];
    }
    _lastNames = pool.take(4).toList();
  }

  void _deal() {
    _assignBotNames();
    deck = [
      for (int s = 0; s < 4; s++)
        for (int r = 2; r <= 14; r++) PCard(r, s)
    ]..shuffle(rng);
    pot = 0;
    stake = boot;
    gameOver = false;
    revealAll = false;
    showChip = false;
    chipAlign = Alignment.center;
    thinking = -1;
    for (final p in players) {
      if (p.chips < boot * 10) p.chips = 5000; // free refill
      p.cards = [deck.removeLast(), deck.removeLast(), deck.removeLast()];
      p.seen = false;
      p.packed = false;
      p.moves = 0;
      p.chips -= boot;
      pot += boot;
    }
    turn = _starter % players.length;
    _starter++;
    message = 'खेल शुरू हुआ! Boot ₹$boot';
  }

  void _newGame() {
    setState(_deal);
    _runTurn();
  }

  // ---------------- turn flow ----------------

  Future<void> _runTurn() async {
    if (gameOver || !mounted) return;
    final idx = turn;
    final p = players[idx];
    if (!p.isBot) {
      setState(() {
        thinking = -1;
        message = 'आपकी बारी है';
      });
      return;
    }
    setState(() => thinking = idx);
    // Bots "think" for 2 to 4 seconds like a real person
    await Future.delayed(Duration(milliseconds: 2000 + rng.nextInt(2001)));
    if (!mounted || gameOver || turn != idx) return;
    _botAct(p);
  }

  void _endTurn() {
    final act = _active;
    if (act.length == 1) {
      _win(act.first);
      return;
    }
    setState(() => turn = _nextActive(turn));
    _runTurn();
  }

  void _botAct(Player p) {
    // A blind bot may decide to look at its cards after a round or two
    if (!p.seen && p.moves >= 1 && rng.nextDouble() < 0.3 + 0.2 * p.moves) {
      setState(() => p.seen = true);
    }
    final res = evaluate(p.cards);
    final activeCount = _active.length;

    if (p.chips < _cost(p)) {
      _pack(p);
      return;
    }

    if (p.seen) {
      var packChance = 0.0;
      if (res.category == 1) {
        packChance = p.moves < 1 ? 0.1 : 0.25 + 0.2 * p.moves;
      } else if (res.category == 2) {
        packChance = p.moves >= 4 ? 0.2 : 0.03;
      }
      if (stake >= 200 && res.category <= 2) packChance += 0.3;
      if (rng.nextDouble() < packChance) {
        _pack(p);
        return;
      }
    } else if (stake >= 100 && rng.nextDouble() < 0.15) {
      _pack(p);
      return;
    }

    // Show when only two players are left
    if (activeCount == 2 && p.moves >= 2 && p.seen && (res.category >= 3 || rng.nextDouble() < 0.15)) {
      _show(p);
      return;
    }

    // Side show (bots only ask another bot)
    if (p.seen && activeCount >= 3 && p.moves >= 2 && res.category >= 3) {
      final prev = _prevActive(p);
      if (prev.isBot && prev.seen && rng.nextDouble() < 0.2) {
        _sideShow(p);
        return;
      }
    }

    var raise = false;
    if (p.seen && res.category >= 4) {
      raise = rng.nextDouble() < 0.4;
    } else if (p.seen && res.category == 3) {
      raise = rng.nextDouble() < 0.2;
    } else if (!p.seen) {
      raise = rng.nextDouble() < 0.1;
    }
    _bet(p, raise);
  }

  // ---------------- actions ----------------

  void _bet(Player p, bool raise) {
    setState(() {
      if (raise && stake * 2 <= maxStake) stake *= 2;
      final cost = _cost(p);
      _pay(p, cost);
      p.moves++;
      message = '${p.name} ने ${p.seen ? "चाल" : "ब्लाइंड"} चली ₹$cost';
    });
    _endTurn();
  }

  void _pack(Player p) {
    setState(() {
      p.packed = true;
      message = '${p.name} ने पैक किया';
    });
    _endTurn();
  }

  void _show(Player p) {
    final other = _active.firstWhere((x) => x != p);
    _pay(p, _cost(p));
    p.moves++;
    final a = evaluate(p.cards).score;
    final b = evaluate(other.cards).score;
    final winner = a > b ? p : other; // on a tie the player who asked loses
    final loser = winner == p ? other : p;
    loser.packed = true;
    message = 'शो! ${winner.name} के कार्ड बड़े निकले';
    _win(winner, reveal: true);
  }

  Future<void> _sideShow(Player req) async {
    final prev = _prevActive(req);
    _pay(req, _cost(req));
    req.moves++;
    final accept = !prev.isBot ||
        rng.nextDouble() < (evaluate(prev.cards).category >= 4 ? 0.25 : 0.75);
    if (!accept) {
      setState(() => message = '${prev.name} ने साइड शो मना कर दिया');
      _endTurn();
      return;
    }
    final a = evaluate(req.cards).score;
    final b = evaluate(prev.cards).score;
    final loser = a > b ? prev : req; // tie: requester loses
    if (!req.isBot) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('साइड शो'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final p in [req, prev]) ...[
              Text(p.name),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: p.cards.map((c) => _face(c, 44)).toList()),
              const SizedBox(height: 8),
            ],
            Text('${loser.name} हार गया'),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है'))],
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      loser.packed = true;
      message = 'साइड शो: ${loser.name} हार गया';
    });
    _endTurn();
  }

  Future<void> _win(Player w, {bool reveal = false}) async {
    final amt = pot;
    setState(() {
      gameOver = true;
      revealAll = reveal;
      thinking = -1;
      chipAmt = amt;
      showChip = true;
      chipAlign = Alignment.center;
      message = w.isBot ? '${w.name} जीता ₹$amt' : 'आप जीत गए! ₹$amt';
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => chipAlign = _seat[players.indexOf(w)]);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      w.chips += amt;
      pot = 0;
      showChip = false;
      chipAlign = Alignment.center;
    });
  }

  // ---------------- UI pieces ----------------

  Widget _face(PCard c, double w) => Container(
        width: w,
        height: w * 1.4,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(c.rankText,
              style: TextStyle(fontSize: w * 0.38, fontWeight: FontWeight.bold, color: c.isRed ? Colors.red : Colors.black)),
          Text(c.suitText, style: TextStyle(fontSize: w * 0.34, color: c.isRed ? Colors.red : Colors.black)),
        ]),
      );

  Widget _back(double w) => Container(
        width: w,
        height: w * 1.4,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.indigo.shade800,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      );

  Widget _tag(Player p) {
    final String t = p.packed ? 'पैक' : (p.seen ? 'देखा' : 'ब्लाइंड');
    final Color c = p.packed ? Colors.grey : (p.seen ? Colors.blue : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
      child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _chipsText(Player p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Text('₹${p.chips}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Widget _botSeat(int i) {
    final p = players[i];
    final active = turn == i && !gameOver;
    final reveal = revealAll && !p.packed;
    return Opacity(
      opacity: p.packed ? 0.5 : 1,
      child: SizedBox(
        width: 100,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _tag(p),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: active ? Colors.amber : Colors.white24, width: 3),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: p.color,
              child: Text(p.name[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          _chipsText(p),
          const SizedBox(height: 2),
          if (!p.packed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: p.cards.map((c) => reveal ? _face(c, 26) : _back(16)).toList(),
            ),
          if (thinking == i) const Text('सोच रहा है...', style: TextStyle(fontSize: 10, color: Colors.amberAccent)),
        ]),
      ),
    );
  }

  Widget _userSeat() {
    final u = players[0];
    final show = u.seen || revealAll;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: u.cards.map((c) => show ? _face(c, 58) : _back(58)).toList(),
      ),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _chipsText(u),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: u.seen ? Colors.blue : Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: (u.seen || u.packed || gameOver) ? null : () => setState(() => u.seen = true),
          child: Text(u.packed ? 'पैक' : (u.seen ? 'देखा ✓' : 'ब्लाइंड - कार्ड देखें')),
        ),
      ]),
      if (u.seen && !u.packed)
        Text(evaluate(u.cards).name, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
    ]);
  }

  Widget _center() => Column(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 22, backgroundColor: Colors.black45, child: Icon(Icons.support_agent, size: 28)),
        const Text('डीलर', style: TextStyle(fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text('पॉट ₹$pot', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 4),
        Text('Stake ₹$stake', style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]);

  Widget _btn(String t, Color c, VoidCallback? f) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
            ),
            onPressed: f,
            child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _controls() {
    if (gameOver) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)),
            onPressed: showChip ? null : _newGame,
            child: const Text('नया खेल', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }
    final u = players[0];
    final my = turn == 0 && !u.packed;
    final cost = _cost(u);
    final newStake = min(stake * 2, maxStake);
    final cost2 = u.seen ? newStake * 2 : newStake;
    final canRaise = stake * 2 <= maxStake && u.chips >= cost2;
    final act = _active;
    final canSide = act.length >= 3 && u.seen && _prevActive(u).seen && u.chips >= cost;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(children: [
        _btn('पैक', Colors.red.shade700, my ? () => _pack(u) : null),
        _btn('चाल\n₹$cost', Colors.green.shade700, (my && u.chips >= cost) ? () => _bet(u, false) : null),
        _btn('2x चाल\n₹$cost2', Colors.teal.shade700, (my && canRaise) ? () => _bet(u, true) : null),
        _btn('साइड शो', Colors.indigo, (my && canSide) ? () => _sideShow(u) : null),
        _btn('शो', Colors.orange.shade800, (my && act.length == 2 && u.chips >= cost) ? () => _show(u) : null),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A0A0A), Color(0xFF2B0505)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(120),
                  border: Border.all(color: Colors.amber.shade700, width: 5),
                  gradient: const RadialGradient(
                    colors: [Color(0xFF1E8E3E), Color(0xFF0B4D1F)],
                    radius: 0.9,
                  ),
                ),
                child: Stack(children: [
                  Align(alignment: Alignment.center, child: _center()),
                  for (int i = 1; i < players.length; i++) Align(alignment: _seat[i], child: _botSeat(i)),
                  Align(alignment: _seat[0], child: _userSeat()),
                  IgnorePointer(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      alignment: chipAlign,
                      child: showChip
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                              child: Text('₹$chipAmt',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            _controls(),
          ]),
        ),
      ),
    );
  }
}
