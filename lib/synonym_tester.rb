class SynonymTester
  def initialize(es_client, source_index_pattern: "govuk,mainstream,government,detailed", source_index_fields: %w(title description indexable_content), index_list: "index_synonym", search_list: "search_synonym")
    @client = es_client
    @source_index_fields = source_index_fields
    @source_index_pattern = source_index_pattern
    @index_list = index_list
    @search_list = search_list
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
    source = source_index_settings
    analysis = source["analysis"]
    filter = analysis["filter"]

    payload = {
      "analysis" => analysis.merge(
        "filter" => filter.merge(
          index_list => {"type" => "synonym", "synonyms" => index_synonyms},
          search_list => {"type" => "synonym", "synonyms" => search_synonyms}
        )
      )
    }

  end

  def copy_data(doc_ids)

  end

  def source_index_settings
    {
      "analysis" => {
        "filter" => {}
      }
    }
  end

  attr_reader :client, :source_index_pattern, :source_index_fields, :index_list, :search_list
end
