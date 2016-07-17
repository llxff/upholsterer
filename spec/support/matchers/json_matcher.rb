RSpec::Matchers.define :be_json_with do |expected|
  match do |json_string|
    current_hash = JSON.parse(json_string)

    compare_hashes(current_hash, expected)
  end

  def compare_hashes(actual, expected)
    if actual.keys.count == expected.keys.count
      actual.all? do |key, value|
        key = key.to_sym
        if expected.has_key?(key)
          expected_value = expected[key]

          if value.is_a? Hash
            if expected_value.is_a? Hash
              compare_hashes(value, expected_value)
            end
          else
            expected_value == value
          end
        end
      end
    end
  end
end

RSpec::Matchers.define :contain_keys do |*expected|
  match do |json_string|
    begin
      @actual = JSON.parse(json_string).keys
      @expected = expected.first
      @actual.sort == @expected.sort
    rescue
      @actual = []
      false
    end
  end
end
