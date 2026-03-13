# frozen_string_literal: true

require 'simplecov_json_formatter/result_hash_formatter'
require 'simplecov_json_formatter/result_exporter'
require 'json'

module SimpleCov
  module Formatter
    # SimpleCov formatter that writes coverage results to a JSON file.
    # Register it with SimpleCov via:
    #   SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
    #
    # The JSON file is written to SimpleCov.coverage_path/coverage.json and
    # contains per-file line/branch coverage data, optional group summaries,
    # and – when SimpleCov.minimum_coverage is configured – boolean flags
    # indicating whether the overall project and each individual file meet
    # the required coverage threshold.
    class JSONFormatter
      # Formats the given SimpleCov::Result, exports it to coverage.json, and
      # prints a summary line to standard output.
      def format(result)
        result_hash = format_result(result)

        export_formatted_result(result_hash)

        puts output_message(result)
      end

      private

      # Converts the SimpleCov::Result into a nested hash via ResultHashFormatter.
      def format_result(result)
        result_hash_formater = SimpleCovJSONFormatter::ResultHashFormatter.new(result)
        result_hash_formater.format
      end

      # Writes the formatted result hash to coverage.json via ResultExporter.
      def export_formatted_result(result_hash)
        result_exporter = SimpleCovJSONFormatter::ResultExporter.new(result_hash)
        result_exporter.export
      end

      # Builds the human-readable summary printed after the report is generated.
      def output_message(result)
        "JSON Coverage report generated for #{result.command_name} to #{SimpleCov.coverage_path}. " \
        "#{result.covered_lines} / #{result.total_lines} LOC (#{result.covered_percent.round(2)}%) covered."
      end
    end
  end
end
