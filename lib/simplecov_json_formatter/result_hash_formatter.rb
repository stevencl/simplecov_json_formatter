# frozen_string_literal: true

require 'simplecov_json_formatter/source_file_formatter'

module SimpleCovJSONFormatter
  # Converts a SimpleCov::Result object into a nested hash ready for JSON export.
  # The resulting structure contains three top-level keys:
  #   - meta:     SimpleCov version and optional overall minimum_coverage_met flag.
  #   - coverage: Per-file line/branch coverage data and statistics.
  #   - groups:   Per-group covered_percent summaries (when groups are configured).
  class ResultHashFormatter
    def initialize(result)
      @result = result
    end

    # Builds and returns the full formatted result hash.
    def format
      format_files
      format_groups

      formatted_result
    end

    private

    # Populates the :coverage section by iterating over every source file in the result.
    def format_files
      @result.files.each do |source_file|
        formatted_result[:coverage][source_file.filename] =
          format_source_file(source_file)
      end
    end

    # Populates the :groups section with covered_percent for each configured group.
    def format_groups
      @result.groups.each do |name, file_list|
        formatted_result[:groups][name] = {
          lines: {
            covered_percent: file_list.covered_percent
          }
        }
      end
    end

    # Returns the memoised top-level result hash, initialised with metadata and
    # empty coverage/groups containers.
    def formatted_result
      @formatted_result ||= {
        meta: meta,
        coverage: {},
        groups: {}
      }
    end

    # Builds the meta hash containing the SimpleCov version and, when
    # SimpleCov.minimum_coverage[:line] is configured, a boolean
    # minimum_coverage_met flag reflecting whether the overall project coverage
    # meets the required threshold.
    def meta
      meta_hash = { simplecov_version: SimpleCov::VERSION }

      min_line_coverage = SimpleCov.minimum_coverage&.[](:line)
      meta_hash[:minimum_coverage_met] = @result.covered_percent >= min_line_coverage unless min_line_coverage.nil?

      meta_hash
    end

    # Delegates formatting of a single source file to SourceFileFormatter.
    def format_source_file(source_file)
      source_file_formatter = SourceFileFormatter.new(source_file)
      source_file_formatter.format
    end
  end
end
