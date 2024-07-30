# frozen_string_literal: true

require 'rspec'
require 'csv'
require 'set'

RSpec.describe 'CSV Uniqueness' do
  let(:file_path) { 'reports/report.csv' }

  def first_column_unique?(file_path)
    first_column_values = Set.new

    CSV.foreach(file_path, headers: true, encoding: 'bom|utf-8') do |row|
      value = row[0]
      return false if first_column_values.include?(value)

      first_column_values.add(value)
    end

    true
  end

  describe '#first_column_unique?' do
    context 'when checking the report.csv file' do
      it 'returns true if the first column is unique' do
        if File.exist?(file_path)
          expect(first_column_unique?(file_path)).to be true
        else
          skip "File #{file_path} does not exist. Skipping test."
        end
      end

      it 'returns false if the first column is not unique' do
        duplicate_file_path = 'reports/report_with_duplicates.csv'
        if File.exist?(duplicate_file_path)
          expect(first_column_unique?(duplicate_file_path)).to be false
        else
          skip "File #{duplicate_file_path} does not exist. Skipping test."
        end
      end
    end
  end
end
