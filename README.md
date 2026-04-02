# Understanding Society Data Extractor

Stata programs for extracting and harmonising data from the UK Household
Longitudinal Study (Understanding Society / UKHLS) across multiple waves.

## What it does

The main program, `usextract`, merges household and individual-level files
from Understanding Society into a single, analysis-ready dataset. It handles:

- Waves 1–15 of Understanding Society
- Merging of household response, household sample, individual, and
  individual response files
- Family structure validation (benefit unit membership, partner links,
  child placement)
- Optional price uprating of monetary variables to a common price level
- Optional cross-wave variable merges

## Requirements

- Stata (tested on recent versions)
- The Understanding Society raw data files, organised by wave in the
  standard UKDS directory structure

## Installation

Copy all `.ado` files into your Stata ado path (e.g. your personal ado
directory, typically `~/ado/personal/`).

## Usage

See `usoc_extract_EXAMPLE.do` for a full worked example. At minimum:

```stata
global ukhls "path/to/ukhls/data"

usextract using "$ukhls", waves(1/15) clear
```

Full option documentation is in the Stata help file:

```stata
help usextract
```

## Files

| File | Purpose |
|------|---------|
| `usextract.ado` | Main extraction program |
| `useundersoc.ado` | Family structure cleaning |
| `usuprate.ado` | Price uprating utility |
| `check_option_syntax.ado` | Option parsing helper |
| `us_*_vars.ado` | Variable creation modules |
| `usextract.sthlp` | Stata help file |
| `usoc_extract_EXAMPLE.do` | Usage example |

## Authors

Peter Levell (Institute for Fiscal Studies), based on an earlier BHPS
extractor by Jonathan Shaw. Wave synchronisation and coding improvements
by David Sturrock.
