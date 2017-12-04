# Synonym tester

CLI utility for quickly rebuilding a stripped down GOV.UK search index,
and swapping out synonym rules.

This is currently a proof of concept.

It requires access to an elasticsearch cluster containing GOV.UK search indexes.

# Usage

`./bin/synonym_tester`

## Completed
- Create a test index with customised analysis settings

## Unfinished
- Define a useful mapping
- Specify synonym rules to test in isolation
- Run test searches
- Report search results

### Dependencies

- [Elasticsearch ruby](https://github.com/elastic/elasticsearch-ruby)

## Licence

[MIT License](LICENCE)
