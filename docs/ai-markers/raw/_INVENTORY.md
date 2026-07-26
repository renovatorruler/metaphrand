# Raw harvest inventory (2026-07-20)

Agent reports: agent1-canonical.md (Wikipedia/academic/detection-industry), agent2-fiction.md (fiction & creative-writing communities), agent3-datadriven.md (computed lexicons & repos).

Machine-readable files (fetched from source repos):
- slop_phrase_prob_adjustments.json — antislop-sampler, 517 scored phrases
- cwb_slop_phrase_prob_adjustments.json — EQ-Bench creative-writing-bench, 50,084 scored entries (1.9MB)
- antislop-vllm_main_banlists_slop_phrases.json — 2,333 phrases with frequency counts
- antislop-vllm_main_banlists_banned_ngrams.json — 400 banned n-grams
- antislop-vllm_main_banlists_regex_not_x_but_y.json — the not-X-but-Y regex suite
- slop-forensics_main_data_slop_list.json / _bigrams.json / _trigrams.json — 1,000 words + 200 + 200
- slopscore_slop_list.json (1,648 words) + slopscore_trigrams.json — the Slop Score engine lists
- kobak_excess_words.csv — 774 excess words with frequency ratios (Science Advances 2025)
- essays_slop_list.json, varied_slop_list.json — additional computed lists
- gist_peter.md, gist_keskinonur.md, gist_abuisman.md, gist_ossama_tropes.md — community banned-phrase gists
- lguz_patterns.md — tiered AI-patterns dictionary; avectats_antiai.md — era-stratified master list
- slop_forensics_README.md — methodology
