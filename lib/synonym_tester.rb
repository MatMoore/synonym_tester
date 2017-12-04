require 'pp'
require 'pry-byebug'

class SynonymTester
  INDEX_FILTER = "index_synonym"
  SEARCH_FILTER = "search_synonym"
  INDEX_ANALYZER = "with_index_synonyms"
  SEARCH_ANALYZER = "with_search_synonyms"
  TEST_INDEX_NAME = "test_index"

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
    []
  end

  def report(query, results)
    puts query
    puts results
  end

  def create_index(index_synonyms, search_synonyms)
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
          "query" => {
            "bool" => {
              "filter" => {
                "ids" => {"values" => doc_ids}
              }
            }
          }
        },
        "dest": {
          "index" => TEST_INDEX_NAME
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
