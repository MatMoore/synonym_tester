require 'pp'
require 'pry-byebug'
require 'rainbow'

class SynonymTester
  INDEX_FILTER = "index_synonym"
  SEARCH_FILTER = "search_synonym"
  INDEX_ANALYZER = "with_index_synonyms"
  SEARCH_ANALYZER = "with_search_synonyms"
  TEST_INDEX_NAME = "test_index"

  ANSI_GREEN = "\e[32m".freeze
  ANSI_RESET = "\e[0m".freeze

  def initialize(es_client, source_index_pattern: "govuk,mainstream,government,detailed", source_index_fields: %w(title description indexable_content))
    @client = es_client
    @source_index_fields = source_index_fields
    @source_index_pattern = source_index_pattern
  end

  def run(queries:, doc_ids:, search_synonyms:, index_synonyms:)
    create_index(index_synonyms, search_synonyms)
    copy_data(doc_ids)
    queries.each do |query|
      results = search(query)
      report(query, results)
    end
  end

private

  def search(query)
    payload = {
      size: 10,
      query: {
        bool: {
          should: [
            {
              match_phrase: {
                "title" => {
                  query: query
                }
              }
            },
            {
              match_phrase: {
                "description" => {
                  query: query
                }
              }
            },
            {
              match_phrase: {
                "indexable_content" => {
                  query: query
                }
              }
            },
            {
              multi_match: {
                query: query,
                operator:"and",
                fields: ["title", "description", "indexable_content"],
              }
            },
            {
              multi_match: {
                query: query,
                operator:"or",
                fields:["title", "description", "indexable_content"]
              }
            },
            {
              multi_match: {
                query: query,
                operator:"or",
                fields:["title", "description", "indexable_content"],
                minimum_should_match: "2<2 3<3 7<50%"
              }
            },
          ]
        }
      },
      highlight: {
        "fields" => { "title" => {}, "description" => {} },
        "pre_tags" => [ANSI_GREEN],
        "post_tags" => [ANSI_RESET]
      }
    }

    client.search(index: TEST_INDEX_NAME, body: payload)
  end

  def report(query, results)
    puts Rainbow(query).yellow
    hits = results["hits"]["hits"]
    if hits.empty?
      puts Rainbow("No results found").red
    else
      hits.each do |hit|
        title = hit.dig("highlight", "title") || hit.dig("_source", "title")
        description = hit.dig("highlight", "description") || hit.dig("_source", "description")
        puts title
        puts description if description
        puts ""
      end
    end
  end

  def create_index(index_synonyms, search_synonyms)
    # Hack around empty synonym list case
    index_synonyms << "xyzzy => konami"
    search_synonyms << "xyzzy => konami"

    begin
      client.indices.delete(index: TEST_INDEX_NAME)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
    end

    analysis = source_index_analysis_settings
    filter = analysis["filter"]

    payload = {
      "settings" => {
        "analysis" => analysis.merge(
          "filter" => filter.merge(
            INDEX_FILTER => {"type" => "synonym", "synonyms" => index_synonyms},
            SEARCH_FILTER => {"type" => "synonym", "synonyms" => search_synonyms}
          )
        )
      },
      "mappings" => test_mappings,
      "index" => {"number_of_shards" => 1, "number_of_replicas" => 0}
    }

    client.indices.create(
      index: TEST_INDEX_NAME,
      body: payload
    )
  end

  def copy_data(doc_ids)
    indexes = client.indices.get(index: source_index_pattern)
    puts "reindexing docs from #{indexes.keys}"

    indexes.keys.each do |source_index|

      payload = {
        "source": {
          "index" => source_index,
          "_source": source_index_fields,
          "query" => {
            "bool" => {
              "filter" => {
                "ids" => {"values" => doc_ids}
              }
            }
          }
        },
        "dest": {
          "index" => TEST_INDEX_NAME,
          "type": "test_type"
        }
      }

      results = client.reindex(body: payload, wait_for_completion:true)
    end
  end

  def test_mappings
    {
      "test_type" => {
        "properties" => source_index_fields.map do |field_name|
          [
            field_name,
            {
              "type": "string",
              "analyzer": INDEX_ANALYZER,
              "search_analyzer": SEARCH_ANALYZER
            }
          ]
        end.to_h
      }
    }
  end

  def source_index_analysis_settings
    results = client.indices.get(index: source_index_pattern)
    results.values.first["settings"]["index"]["analysis"]
  end

  attr_reader :client, :source_index_pattern, :source_index_fields
end
