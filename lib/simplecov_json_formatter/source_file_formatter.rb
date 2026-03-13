# frozen_string_literal: true

module SimpleCovJSONFormatter
  # Formats a single SimpleCov::SourceFile into a hash suitable for JSON serialisation.
  # Produces line coverage data, optional branch coverage data, and per-file
  # coverage statistics. When a minimum line coverage threshold is configured via
  # SimpleCov.minimum_coverage, it also emits a boolean +minimum_coverage_met+ flag
  # so consumers can identify which files fall below the threshold.
  class SourceFileFormatter
    def initialize(source_file)
      @source_file = source_file
      @line_coverage = nil
    end

    # Returns the formatted coverage hash for the source file.
    # Always includes line coverage and statistics; includes branch coverage
    # when SimpleCov branch coverage tracking is enabled.
    def format
      result = if SimpleCov.branch_coverage?
                 line_coverage.merge(branch_coverage)
               else
                 line_coverage
               end
      result.merge(coverage_statistics)
    end

    private

    # Builds the { lines: [...] } hash, memoised so it can be safely merged
    # with branch_coverage without re-computing the line array.
    def line_coverage
      @line_coverage ||= {
        lines: lines
      }
    end

    # Builds the { branches: [...] } hash for branch coverage data.
    def branch_coverage
      {
        branches: branches
      }
    end

    # Maps each source line to its coverage value or "ignored" for skipped lines.
    def lines
      lines = []
      @source_file.lines.each do |line|
        lines << parse_line(line)
      end

      lines
    end

    # Maps each branch to a hash describing its location and hit count.
    def branches
      branches = []
      @source_file.branches.each do |branch|
        branches << parse_branch(branch)
      end

      branches
    end

    # Returns the coverage count for a line, or "ignored" when the line is
    # excluded via a #:nocov: marker.
    def parse_line(line)
      return line.coverage unless line.skipped?

      'ignored'
    end

    # Converts a SimpleCov branch object to a plain hash with type, line range,
    # and coverage count.
    def parse_branch(branch)
      {
        type: branch.type,
        start_line: branch.start_line,
        end_line: branch.end_line,
        coverage: parse_line(branch)
      }
    end

    # Builds per-file coverage statistics hash.
    # Always includes covered_percent, covered_lines, and total_lines.
    # Adds minimum_coverage_met (boolean) when SimpleCov.minimum_coverage[:line] is set,
    # indicating whether this file meets the configured line coverage threshold.
    def coverage_statistics
      stats = {
        covered_percent: @source_file.covered_percent.round(2),
        covered_lines: @source_file.covered_lines.count,
        total_lines: @source_file.lines_of_code
      }

      min_line_coverage = SimpleCov.minimum_coverage&.[](:line)
      stats[:minimum_coverage_met] = @source_file.covered_percent >= min_line_coverage unless min_line_coverage.nil?

      stats
    end
  end
end
