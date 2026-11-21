# Aşama 1a — Sözde Kod: Kelime Tespiti, Puanlama, Oyun Sonu, Motor

Durum: ONAY BEKLİYOR. Koordinatlar: x = sütun (0..7, soldan sağa), y = satır (0..7, yukarıdan aşağıya).

## 0. Ortak yapılar

```
ALPHABET = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ"     // index 1..29 (0 = boş)
letterScore(cell) = cell.isJoker ? 0 : SCORE_TABLE[cell.letter]
LEN_MULT_X10 = {3:10, 4:15, 5:20, 6:30, 7:40, 8:60}  // tamsayı aritmetiği için ×10

// Kelime anahtarı: harf başına 5 bit, en fazla 8 harf = 40 bit (native Dart int 64 bit).
encode(letters) = Σ index(letters[i]) << (5*i)
// Sözlük çalışma zamanında Set<int> olarak tutulur → contains() O(1), bellek ayırma yok.
```

## 1. Kelime tespiti

```
function detectWords(grid, newCells, dict, MIN_LEN) -> List<WordHit>
    // 1. Etkilenen hatlar: yeni hücrelerin satırları ve sütunları (tekrarsız)
    lines = {}
    for c in newCells:
        lines.add((HORIZONTAL, row = c.y))
        lines.add((VERTICAL,   col = c.x))

    hits = []
    for line in lines:
        coords = line.coordsInReadingOrder()        // 8 koordinat
        for seg in maximalRuns(coords, grid):       // kesintisiz dolu hücre dizileri
            if seg.length < MIN_LEN: continue
            if none(seg, isNew): continue

            // 2. Aday alt diziler
            cands = []
            for start in 0 .. seg.length - MIN_LEN:
                for len in MIN_LEN .. min(8, seg.length - start):
                    sub = seg[start ..< start+len]
                    if none(sub, isNew): continue                  // kural 2.5b
                    if dict.contains(encode(sub.letters)):
                        cands.add({start, len, letterSum = Σ letterScore(sub)})

            // 3. Çakışma çözümü (açgözlü) — kural 2.5c/d
            sort cands by (len DESC, letterSum DESC, start ASC)
            takenMask = 0                                         // segment içi bit maskesi
            for k in cands:
                m = bits(k.start ..< k.start + k.len)
                if takenMask & m == 0:
                    takenMask |= m
                    hits.add(WordHit(word, cells = seg[k.start ..< k.start+k.len],
                                     direction = line.dir))
    return hits      // yatay ve dikey isabetler hücre paylaşabilir — kural 2.5e

function resolveClear(grid, hits) -> clearedCells
    cleared = union(h.cells for h in hits)      // paylaşılan hücre bir kez
    for c in cleared: grid[c] = null
    return cleared                               // yeniden tarama YOK — kural 2.5f
```

Notlar:
- Bir parça en fazla 3×2 / 4×1 alana yayılır → en fazla 6 hat; segment ≤ 8 → hat başına ≤ 21 alt dizi
  (MIN_LEN 3). Hamle başına üst sınır ~130 sözlük sorgusu → hedef 5 ms'nin çok altında.
- Kodda listeler yerine önceden ayrılmış sabit tamponlar kullanılır (oyun ekranında kare başına ayırma yok).
- VARSAYIM: Normal oyunda eski hücreler kendi başına kelime oluşturmaz (oluşsaydı daha önce patlardı);
  "yeni hücre" şartı sözlük güncellemesi / kayıt geçişi gibi durumlar için de bir güvencedir.

## 2. Puanlama (saf fonksiyon)

```
function scoreMove(hits, placedCount, gridEmptyAfter, streakBefore) -> (MoveScore, streakAfter)
    if hits.isEmpty:
        return ({words: 0, placement: placedCount, clear: 0, total: placedCount}, streakAfter = 0)

    // a) kelime puanları (×10 ölçekte, kesirsiz)
    base10 = Σ over h in hits: (Σ letterScore(c) for c in h.cells) * LEN_MULT_X10[h.len]

    // b) kombo
    combo = hits.length

    // c) seri
    streakAfter = streakBefore + 1
    streak10 = min(10 + (streakAfter - 1), 20)        // 1.0, 1.1, ... 2.0

    // d) yuvarlama (aşağı) — tek seferde, tamsayı bölme
    wordPart = floor(base10 * combo * streak10 / 100)

    // e) yerleştirme ve boş ızgara
    placement = placedCount * 1
    clear = gridEmptyAfter ? 100 : 0

    return ({wordPart, placement, clear, total = wordPart + placement + clear}, streakAfter)
```

VARSAYIM'lar:
- Joker: harfi 0 puan, kelime tespiti tetiklenir, yerleştirme bonusu **0** (blok değil, güçlendirici).
  Kelime kurarsa seri artar; kurmazsa seri değişmez (karar 13).
- Çekiç ile ızgara boşalırsa +100 **verilmez** (bonus yalnızca kelime patlamasıyla).
- +100 yalnızca hamleden önce ızgarada taş varken verilir: boş ızgaraya tek başına kelime olan
  bir blok koymak "temizleme" sayılmaz. Klasik kolaylaştırıcı da boş ızgarada çalışmaz
  (web testinde bulunan açık, Aşama 2 sonrası).
- Kombo çarpanı patlayan kelime sayısıdır (yatay + dikey birlikte).

## 3. Oyun sonu kontrolü

```
// Izgara 64 bitlik doluluk maskesi; her şekil ve her ofset için maske önceden hesaplanır.
function fits(occ, shape, x, y) = (occ & SHAPE_MASK[shape][x][y]) == 0

function canPlaceAny(occ, hand) -> bool
    for piece in hand where not piece.used:
        for (x, y) in validOffsets(piece.shape):
            if fits(occ, piece.shape, x, y): return true
    return false

function checkGameOver(state) -> Next
    if canPlaceAny(state.occ, state.hand): return Idle
    if state.mode == DAILY: return GameOver                   // güçlendirici/devam yok
    usable = [p for p in [REFRESH, HAMMER, JOKER] if state.powerups[p] > 0]
    if usable.notEmpty: return OfferPowerup(usable)           // "Güçlendirici kullan?"
    return GameOver                                           // oyun sonu ekranında ödüllü devam (oyun başına 1)
```

## 4. Motor ve durum makinesi

```
Idle --dragStart--> Dragging --drop(valid)--> Placing --> Resolving --> Refilling --> CheckGameOver
                    Dragging --drop(invalid)--> Idle (yay ile geri dönüş)
CheckGameOver --> Idle | OfferPowerup | GameOver
Resolving sırasında girdi kilitli.

function applyMove(state, move) -> (newState, events)          // saf, arayüzden bağımsız
    piece = state.hand[move.pieceIndex]
    assert not piece.used and fits(state.occ, piece.shape, move.x, move.y)
    newCells = place(state.grid, piece, move.x, move.y)
    hits     = detectWords(grid, newCells, dict, cfg.MIN_WORD_LEN)
    cleared  = resolveClear(grid, hits)
    (score, streak) = scoreMove(hits, newCells.length, grid.isEmpty, state.streak)
    piece.used = true
    if all(hand, used):
        state.handNo += 1
        hand = generateHand(rngFor(state.seed, state.handNo), grid, mode, score)   // karar 5
    state.moves.add(move)
    events = [Placed(newCells), WordsFound(hits), Cleared(cleared), Scored(score), NewHand?]
    return (state, events)                                      // arayüz yalnızca events'i canlandırır

function replay(seed, mode, moves) -> GameState                 // Düello ve testler için
    s = newGame(seed, mode)
    for m in moves: s = applyMove(s, m).state
    return s
```

## 5. Elle hesaplanmış örnekler (birim testlerine dönüşecek)

Harf puanları: K1 A1 R1 E1 L1 M2.

| # | Durum | Hesap | Sonuç |
|---|---|---|---|
| 1 | Boş satıra `K A R` (3 hücre) konur, seri 0 | KAR = 3 × 1.0 = 3; kombo 1; seri ×1.0 → 3; +3 yerleştirme | **6**, seri 1 |
| 2 | Yatay KALEM (5) + dikey ELMA (4), E paylaşımlı, 3 hücre konur, önceki seri 2 | base10 = 6·20 + 5·15 = 195; ×2 kombo; ×1.2 seri → 195·2·12/100 = 46.8 → 46; +3 | **49**, seri 3 |
| 3 | Segment `E L M A K A R`, sözlükte ELMA ve KAR (çakışmıyor), seri 0, ortadaki `A K` (2 hücre) konur | ELMA 5·15=75, KAR 3·10=30 → base10 105; ×2 kombo; ×1.0 → 21; +2 | **23**, seri 1 |
| 4 | Segment `A R A B A`, aday ARA(0-2) ve ARABA(0-4) | çakışma → ARABA (uzun) kazanır; ARA atılır | 1 kelime |
| 5 | Kelime oluşmayan hamle, 4 hücre, önceki seri 5 | kelime yok | **4**, seri 0 |
| 6 | Örnek 1 sonucunda ızgara tamamen boşalır | 3 + 3 + 100 | **106** |
| 7 | Seri sınırı: önceki seri 15, KAR | 3·10·1·20/100 = 6 | **6 + yerleştirme**, seri 16 (çarpan ×2.0'da kalır) |

Not: Örnekler 3 ve 4, ilgili kelimelerin (ve "AKAR", "MAKAR" vb.'nin olmadığının) sözlükte doğrulanmasına bağlıdır;
testlerde sabit, küçük bir test sözlüğü kullanılacak.
