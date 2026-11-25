# English dictionary sources (karar 29)

Downloaded 25 November 2026 with the owner's approval. Only the files the build reads are kept;
`dart run tool/build_dictionary_en.dart` turns them into `assets/dict/{words,common}_en.bin`.

## SCOWL 2020.12.07 — valid words

- Project: http://wordlist.aspell.net/ (Kevin Atkinson)
- Archive: https://downloads.sourceforge.net/project/wordlist/SCOWL/2020.12.07/scowl-2020.12.07.tar.gz
  (2,569,810 bytes, sha256 `5587667caa20c4891390c2d42dbb4d5c4c3f41bee77af1457ece3ba23fb859cc`)
- Kept: `final/{english,american,british}-words.{10,20,35,40,50,55,60}`, `Copyright`, `VERSION`.
  Size 60 is the usual spell-checker size; names, abbreviations and contractions live in other
  SCOWL files and are not used. American and British spellings are both accepted.
- License: `scowl-2020.12.07/Copyright` (permission to use, copy, modify, distribute and sell,
  provided the notice appears in all copies and in supporting documentation). The app shows it
  on its licenses page (`assets/config/SCOWL_LICENSE.txt`).

## 12dicts 6.0.2 — common words

- Project: http://wordlist.aspell.net/12dicts/ (Alan Beale)
- Archive: https://downloads.sourceforge.net/project/wordlist/12Dicts/6.0/12dicts-6.0.2.zip
  (1,992,138 bytes, sha256 `64ac1d35acb66b550c7ebc56e080b62e0bad8f5984d72059dc2e05ac48780e52`)
- Kept: `Lemmatized/2+2+3frq.txt` (lemmas in 21 frequency classes; indented lines list irregular
  forms) and `agid.txt`.
- License: released to the public domain by Alan Beale, who asks for acknowledgment; the 2+2+3
  lists depend on AGID, whose terms are in `agid.txt`. Both are shown on the app's licenses page
  (`assets/config/12DICTS_LICENSE.txt`).
