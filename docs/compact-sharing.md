# Compact comparison links

Links put the comparison settings directly in the path as URL-safe Base64 text. There is no query parameter, version number, checksum, or property-name text. Previous formats are not supported.

## Complete list of stored values

| Value | Details |
| --- | --- |
| Ordered bike/build selections | Permanent numeric configuration IDs; the bike model and upgrade details are derived from each ID. Both count and order follow the sequence of complete entries, with no count or order field. |
| Weight preset per comparison | Permanent numeric preset ID. Zero identifies a custom weight. The preset's weight is looked up in the app and is not stored in the link. |
| Custom bike weight | An explicit full-precision pound value, present only for custom weights. |
| Chart mode | Both, horsepower, or torque. |
| Per-100-pound setting | On/off, applies to horsepower and torque together. |
| Include rider and gear | On/off, applies the same load to all comparisons. |
| Rider weight | Pound value, present only when nonzero. The number input rounds new entries to whole pounds. A nonzero value remains in the link when load is disabled, so re-enabling the switch restores it. |
| Gear weight | Same rules as rider weight. |

Two presence flags indicate whether rider and gear values follow. These share one byte with chart mode, normalization, and load inclusion. The decoder reads complete comparison entries until the payload ends, enforcing a limit of one to four entries.

Colors, torque units, open panel, selected source, library category, and library search text are not stored. Default colors follow comparison order. Torque is always shown in pound-feet (`lb-ft`, or `lb-ft/100 lb` when normalized), with no unit selector. Shared links open the comparison view with default library/source navigation state. Visibility, cursor and scroll positions, unfinished numeric input, and temporary menus are also excluded. Local browser storage can retain navigation and visibility preferences independently of the shared URL.

## Measurements

| Example | State characters | Complete public URL characters |
| --- | ---: | ---: |
| Two preset bikes | 6 | 37 |
| Two preset bikes + 181 lb rider and 22 lb gear | 11 | 42 |
| Three bikes, two custom weights + 200 lb rider and 20 lb gear | 18 | 49 |

Reproduce the measurements with `dart scripts/report_share_sizes.dart`. That script also compares the complete original JSON format.

Example: `https://moto.bendtrailmaps.com/AGDCAQ` describes Honda CRF300L stock with the Rally weight preset and KTM 390 stock with the Enduro weight preset, Both mode, unnormalized, and no rider or gear load.

## Encoding and validation

The payload starts with one byte of option flags. Each run packs a five-bit configuration code and a numeric preset code into a variable-length integer. Configuration code 31 escapes to an additional numeric code, allowing the catalog to grow. Only custom weights and nonzero rider/gear values add explicit numbers. Common decimal values use exact scaled integers; other numbers use IEEE-754 binary64. The version field used in local browser storage is independent and is not included in the URL.

Permanent catalog codes live in `lib/share_catalog.dart`. Append entries; never reorder or remove them. Preset reference weights are frozen: append a new entry if a reference weight changes.

The decoder validates the URL-safe alphabet, canonical Base64 encoding, catalog IDs, weights, flags, complete entries, and the one-to-four-comparison limit. Invalid state is silently ignored. Truncating within an entry is invalid; truncating at a complete entry produces a valid shorter comparison. Unrelated query parameters and URL fragments are preserved; old `s` and `state` parameters are removed when writing the current link. There is no URL-shortening service, backend storage, expiration, or new dependency.

Cloudflare's existing single-page-application asset fallback serves direct path links and reloads. Flutter's root base URL keeps WebAssembly, scripts, fonts, and chart resources loading from the correct locations. The local release preview also supports path links.
