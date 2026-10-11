# References Mode

Find, verify and format the references of a research document. When you finish, every reference is real and resolvable, its metadata matches the source, every claim that needs a citation has one that supports it, every cited key exists, every entry is cited, and the style is consistent.

## Rules

1. **Nothing from memory.** Every author list, title, venue, year, volume, page range and identifier comes from a registry record or publisher page you fetched in this session. Model memory is a search hint, never a source
2. **Resolvable or flagged.** Each entry has a DOI, or a stable identifier (arXiv id, PubMed id, ISBN, ACL Anthology id, handle), or a stable URL. An entry you cannot resolve stays in the report as unresolvable. It is never patched with a guess
3. **Record wins.** When the entry and the record disagree, the record wins, unless the user cites a different version on purpose (a preprint with content the published version dropped). Say which version is cited
4. **Support, not decoration.** A citation must support the sentence it sits in. A real paper cited for something it does not say is a finding
5. **No silent deletion.** Uncited entries and unsupported citations are reported. Remove or replace them only when the user agrees

## Step 1. Inventory

Run cite-check on the folder that holds the document and its bibliography:

```
bash "<skill-dir>/scripts/cite-check.sh" "<folder>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/cite-check.ps1" -Path "<folder>"
```

| Code | Meaning | Next step |
|------|---------|-----------|
| MISSING_KEY | Cited in the text but defined nowhere | Find the intended source and add a verified entry, or fix the key typo |
| UNCITED | In the bibliography but never cited | Ask whether it belongs in the text or should go. Some styles list uncited works on purpose (`\nocite`) |
| NO_LOCATOR | No DOI, URL, eprint or ISBN | Resolve it in Step 2 |
| MISSING_FIELD | No title, author or year | Fill it from the record |
| BAD_DOI | The DOI field is not a DOI | Find the real DOI or remove the field |
| DUP_KEY, DUP_DOI, DUP_TITLE | The same work entered twice | Merge into one key and update every citation of the other key |
| DOI_NOT_FOUND (online) | Crossref has no such DOI | Try DataCite (`https://api.datacite.org/dois/<doi>`) and `https://doi.org/<doi>`. If both fail, treat the entry as unresolvable and possibly fabricated |
| TITLE_MISMATCH, YEAR_MISMATCH (online) | The DOI points to a different work or version | Compare the full record. Often the DOI belongs to another paper |
| DOI_UNCHECKED (online) | The request failed | Retry later or check by hand |

Run `--online` (`-Online`) when the network is available. It is polite (one request per second) and sends only DOIs. Pass `--mailto` only with an address the user gave you.

For Markdown with numbered references and no keys, or for plain text, build the inventory by hand: list every in-text citation marker and every reference list item, then match them.

## Step 2. Resolve Every Entry

Look up each entry in this order and stop at the first confident match.

| Have | Look up |
|------|---------|
| DOI | `https://api.crossref.org/works/<doi>`, then DataCite for DOIs Crossref does not hold (arXiv, Zenodo, figshare, many datasets) |
| arXiv id | `http://export.arxiv.org/api/query?id_list=<id>`. Then search for a published version of the same title |
| PubMed id or a biomedical title | `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=<pmid>&retmode=json` |
| ISBN | `https://openlibrary.org/isbn/<isbn>.json`, then the publisher page |
| Only a title and authors | `https://api.crossref.org/works?query.bibliographic=<title and first author>&rows=5`, `https://api.openalex.org/works?search=<title>`, and for computer science `https://dblp.org/search/publ/api?q=<title>&format=json` |
| Web page, software, dataset | The page itself. Record the URL, the version or release, and the access date. Prefer an archived DOI (Zenodo) for software and data |

A match is confident only when the normalized title matches, the first author's family name matches, and the year is within one. A near match on title alone is a candidate, not a match.

To build a clean BibTeX entry from a DOI, ask the registry for it: `curl -sL -H "Accept: application/x-bibtex" "https://doi.org/<doi>"`. Then tidy it to the document's style. Keep the user's existing key so citations do not break.

## Step 3. Verify the Metadata

Compare each entry with its record field by field.

| Field | Must match | Common errors |
|-------|-----------|---------------|
| Title | Same words after case and punctuation, subtitle included | Truncated subtitle, title of a different paper by the same authors, lost capitals (protect them in BibTeX with braces, such as `{BERT}` or `{COVID-19}`) |
| Authors | Every author, in order, spelled as in the record | Missing authors, swapped order, invented middle initials, "et al." written into the field |
| Venue | The journal or proceedings named in the record | Workshop cited as main conference, preprint cited as published, wrong year of the proceedings |
| Year | The year of the version cited | Online first year versus issue year. Use the issue year for journals and say so when they differ |
| Volume, issue, pages | As in the record, or an article number when the venue uses them | Pages from another paper in the same issue |
| Identifier | Resolves to this exact work | DOI of a related paper, DOI with a trailing period or a `https://doi.org/` prefix inside the field |
| Status | Not retracted, or the retraction is cited on purpose | Retracted papers cited as support. Check the record's update and relation fields and the publisher page |

## Step 4. Check Every Claim That Needs a Citation

Read the text sentence by sentence. A sentence needs a citation when it states something the document did not produce itself.

| Needs a citation | Example |
|------------------|---------|
| A number or statistic from outside the work | "Two thirds of hospitals now use electronic records" |
| A prior result or finding | "Earlier trials found no effect in older adults" |
| A claim of priority, popularity or state of the art | "the first", "widely used", "the strongest baseline" |
| A method, metric, dataset, instrument or theory the authors did not create | "We use the System Usability Scale" |
| Software, models and tools | Name, version and the paper or archive the developers ask users to cite |
| A direct quote | Also needs the page or paragraph number |
| Background that is not common knowledge in the field | Use the field's judgment, and when in doubt cite |

No citation needed: the document's own results, plain logic, and facts every reader in the field knows.

For each cited sentence, open the source (at least the abstract, and the full text when the claim is a specific number, quote or finding) and give a verdict.

| Verdict | Meaning |
|---------|---------|
| Supports | The source states this claim |
| Partly supports | The source says something narrower, weaker or in a different setting |
| Does not support | The source does not say this, or says the opposite |
| Not checked | The full text was not accessible. Say so, never guess |

Never mark a citation as supporting from its title alone.

## Step 5. Find New References

When a claim has no citation, or the user asks for sources:

1. Turn the claim into two or three search queries with its key terms and synonyms
2. Search the registries in Step 2 and the web, and prefer peer reviewed primary sources over secondary summaries
3. Snowball from the best hit: the works it cites and the works that cite it (OpenAlex lists both)
4. Include the strongest and most recent competing work, not only work that agrees
5. Show each candidate with its identifier, a one line reason it fits, and its verdict from Step 4. The user picks. Do not insert a candidate into the document before its record is verified

## Step 6. Make the Style Consistent

- One citation system across the document (numeric, author and year, or notes), matching the venue
- One family of citation commands in LaTeX (natbib or biblatex), no hand typed numbers like `[12]` next to keys
- One bibliography style file or CSL style, not hand formatted entries mixed with generated ones
- Author names, venue names (all full or all abbreviated), page ranges (`--` in BibTeX) and title case handled the same way in every entry
- The DOI in the `doi` field, not in `note` or `url`. A URL only where there is no DOI, unless the style wants both
- Entry types that fit the work (`@inproceedings` for conference papers, `@misc` or `@software` for code)

## Output

Write `research-references-<slug>-<YYYYMMDD>/report.md` from [../templates/references-template.md](../templates/references-template.md):

1. Summary counts: entries, verified, corrected, unresolvable, uncited, missing keys, claims without support
2. One row per entry: key, status (verified, corrected, mismatch, unresolvable, missing, uncited), what is wrong, evidence (the registry link you checked) and the fix
3. Claims table: location, quoted sentence, citation, verdict, fix
4. Candidate sources, if any were requested, each with its identifier
5. Style fixes

When the user asks you to apply the fixes, edit the `.bib` and the text, keep keys stable, rerun cite-check, and report what changed.
