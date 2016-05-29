RSpec::Matchers.define :be_json_with do |expected|
  match do |json_string|
    actual_hash = JSON.parse(json_string).sort_by(&:first)
    expected_hash = expected.sort_by(&:first)

    Hash[actual_hash].to_json == Hash[expected_hash].to_json
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
