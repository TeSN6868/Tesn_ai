from pathlib import Path

p = Path("lib/main.dart")
s = p.read_text()

old = """                onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item['title']} siap diaktifkan.')),
                        );
                      },"""

new = """                onTap: () {
                  final title = item['title'] as String;

                  // ===== AKUN & PROFIL =====
                  if (title == 'Edit Nama' ||
                      title == 'Foto Profil' ||
                      title == 'Background Profil') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BJoProfilePage(
                          user: user,
                          token: token,
                        ),
                      ),
                    );
                    return;
                  }

                  // ===== M8 PIN =====
                  if (title == 'M8 PIN') {
                    final pin = user['m8_pin']?.toString().trim() ?? '';

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.pin_outlined, color: m8Blue),
                            SizedBox(width: 10),
                            Text(
                              'M8 PIN',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'M8 PIN adalah identitas akunmu di B’Jo.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: m8WhiteSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                pin.isEmpty
                                    ? 'M8 PIN belum tersedia'
                                    : pin,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: m8Blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // ===== IDENTITAS AKUN =====
                  if (title == 'Identitas Akun') {
                    final name =
                        user['name']?.toString().trim() ?? '';
                    final pin =
                        user['m8_pin']?.toString().trim() ?? '';
                    final bio =
                        user['bio']?.toString().trim() ?? '';

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              color: m8Blue,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Identitas Akun',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _identityRow(
                                Icons.badge_outlined,
                                'Nama',
                                name.isEmpty ? '-' : name,
                              ),
                              const SizedBox(height: 12),
                              _identityRow(
                                Icons.pin_outlined,
                                'M8 PIN',
                                pin.isEmpty ? '-' : pin,
                              ),
                              if (bio.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _identityRow(
                                  Icons.edit_note_rounded,
                                  'Tentang Aku',
                                  bio,
                                ),
                              ],
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BJoProfilePage(
                                    user: user,
                                    token: token,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Edit Profil'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // ===== FALLBACK =====
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title siap digunakan.'),
                    ),
                  );
                },"""

if old not in s:
    raise SystemExit("ERROR: blok handler lama tidak ditemukan")

s = s.replace(old, new, 1)

marker = "class _SettingsDetailPage extends StatefulWidget {"

helper = r"""
Widget _identityRow(
  IconData icon,
  String label,
  String value,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: m8WhiteSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: m8Blue),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: m8TextMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

"""

if marker not in s:
    raise SystemExit(
        "ERROR: posisi _SettingsDetailPage tidak ditemukan"
    )

if "_identityRow(IconData icon, String label, String value)" not in s:
    s = s.replace(marker, helper + marker, 1)

p.write_text(s)
print("OK: SEMUA MENU AKUN & PROFIL SUDAH DISAMBUNGKAN")
