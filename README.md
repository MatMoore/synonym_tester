# Synonym tester

CLI utility for quickly rebuilding a stripped down GOV.UK search index,
and swapping out synonym rules.

This is currently a proof of concept.

It requires access to an elasticsearch cluster containing GOV.UK search indexes.

# Example usage

Each argument is a [synonym rule](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-synonym-tokenfilter.html#_solr_synonyms) to swap into either of the synonym filters (identified by the part before the colon).

`./bin/synonym_tester 'search: 1, one' 'both: license => licence', 'index: car => car, vehicle'`

### Dependencies

- [Elasticsearch ruby](https://github.com/elastic/elasticsearch-ruby)

## Licence

[MIT License](LICENCE)
