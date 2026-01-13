import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MainApp());

String pretty(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE6F4FF);
    const appBarBg = Color(0xFFD7EEFF);
    const textDark = Color(0xFF0A3D62);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokedex',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: appBarBg,
          foregroundColor: textDark,
          elevation: 0,
        ),
      ),
      home: const PokemonListScreen(),
    );
  }
}

class PokemonListItem {
  final String name, url;
  final int id;
  PokemonListItem({required this.name, required this.url, required this.id});

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  static int idFromUrl(String url) {
    final seg = Uri.parse(url).pathSegments.where((e) => e.isNotEmpty).toList();
    return int.parse(seg.last);
  }
}

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});
  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  static const int gen1 = 151, pageSize = 20;
  int _offset = 0;
  bool _grid = false, _loading = false, _hasMore = true;
  final List<PokemonListItem> _list = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    if (_offset >= gen1) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loading = true);
    final limit = (gen1 - _offset) < pageSize ? (gen1 - _offset) : pageSize;

    try {
      final uri = Uri.parse(
          'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$_offset');
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List).cast<Map<String, dynamic>>();

      final items = results.map((e) {
        final name = e['name'] as String;
        final url = e['url'] as String;
        return PokemonListItem(name: name, url: url, id: PokemonListItem.idFromUrl(url));
      }).where((p) => p.id <= gen1).toList();

      setState(() {
        _list.addAll(items);
        _offset += limit;
        if (_offset >= gen1 || items.isEmpty) _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _needMore(ScrollNotification n) =>
      _hasMore &&
      !_loading &&
      n.metrics.maxScrollExtent > 0 &&
      n.metrics.pixels >= n.metrics.maxScrollExtent - 200;

  void _open(PokemonListItem p) {
    final tag = 'poke-${p.id}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          id: p.id,
          name: p.name,
          detailUrl: p.url,
          imageUrl: p.imageUrl,
          heroTag: tag,
        ),
      ),
    );
  }

  Card _card({required Widget child, EdgeInsets? pad}) => Card(
        color: Colors.white.withOpacity(0.92),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(padding: pad ?? const EdgeInsets.all(12), child: child),
      );

  // ✅ รูปแรก (List view) ขนาดปกติ
  Widget _listTile(PokemonListItem p) {
    final tag = 'poke-${p.id}';
    final idText = '#${p.id.toString().padLeft(3, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(p),
      child: _card(
        child: Row(
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  p.imageUrl,
                  width: 64, // ✅ ปกติ
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(idText,
                      style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(pretty(p.name),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A3D62))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF0A3D62)),
          ],
        ),
      ),
    );
  }

  // ✅ รูปสอง (Grid view) ให้เล็กลง
  Widget _gridTile(PokemonListItem p) {
    final tag = 'poke-${p.id}';
    final idText = '#${p.id.toString().padLeft(3, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(p),
      child: _card(
        pad: const EdgeInsets.all(8), // ✅ การ์ดเล็กลง
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(idText,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Center(
                child: Hero(
                  tag: tag,
                  child: SizedBox(
                    width: 95,  // ✅ จำกัดรูปให้เล็กลง
                    height: 95,
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(pretty(p.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0A3D62))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _grid
        ? GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 76),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,          // ✅ 3 ช่อง -> ดูเล็กลงทันที
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,     // ✅ กระชับ
            ),
            itemCount: _list.length,
            itemBuilder: (_, i) => _gridTile(_list[i]),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 76),
            itemCount: _list.length,
            itemBuilder: (_, i) => _listTile(_list[i]),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokedex (Gen1)'),
        actions: [
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (_needMore(n)) _fetch();
          return false;
        },
        child: Stack(
          children: [
            body,
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_loading || !_hasMore) ? null : _fetch,
                        icon: const Icon(Icons.download),
                        label: Text(_hasMore
                            ? 'Load more (${_list.length}/151)'
                            : 'ครบแล้ว: 151 ตัว'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_loading)
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PokemonDetailScreen extends StatefulWidget {
  final int id;
  final String name, detailUrl, imageUrl, heroTag;

  const PokemonDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.detailUrl,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse(widget.detailUrl));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      _d = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Card _card(Widget child) => Card(
        color: Colors.white.withOpacity(0.92),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Chip _chip(String t) => Chip(
        label: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.blue.shade50,
        shape: StadiumBorder(side: BorderSide(color: Colors.blue.shade200)),
      );

  Widget _statRow(String name, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(name)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (value / 200).clamp(0.0, 1.0),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 32, child: Text('$value')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title =
        '#${widget.id.toString().padLeft(3, '0')}  ${pretty(widget.name)}';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _d == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('เกิดข้อผิดพลาด: $_error')),
      );
    }

    final d = _d!;
    final types = (d['types'] as List)
        .map((t) => pretty(t['type']['name'] as String))
        .toList();
    final abilities = (d['abilities'] as List)
        .map((a) => pretty(a['ability']['name'] as String))
        .toList();
    final stats = (d['stats'] as List).map((s) {
      return {
        'name': pretty(s['stat']['name'] as String),
        'value': s['base_stat'] as int,
      };
    }).toList();

    final height = (d['height'] as int) / 10;
    final weight = (d['weight'] as int) / 10;

    Widget titleRow(String t) => Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0A3D62),
                ),
          ),
        );

    Widget infoBox(String label, String value) => Expanded(
          child: _card(
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(value),
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Hero(
                      tag: widget.heroTag,
                      child: Image.network(
                        widget.imageUrl,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: types.map(_chip).toList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                infoBox('Height', '${height.toStringAsFixed(1)} m'),
                const SizedBox(width: 12),
                infoBox('Weight', '${weight.toStringAsFixed(1)} kg'),
              ],
            ),
            const SizedBox(height: 16),
            titleRow('Abilities'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: abilities.map(_chip).toList()),
            const SizedBox(height: 16),
            titleRow('Base Stats'),
            const SizedBox(height: 8),
            _card(
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: stats
                      .map((s) => _statRow(s['name'] as String, s['value'] as int))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
