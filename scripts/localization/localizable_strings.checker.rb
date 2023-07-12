# Using `ja.lproj/Localizable.strings` as a reference, this checks the following validation:
# 1. Verification that the keys in 'ja' are also present in the other .strings files.
# 2. Verification that the comments in 'ja' are also present in the other .strings files.
# 3. If the values in 'ja' strings contain the replacable characters like "%%", "%s", "%1$s", "%@", "%1$@", "%d", "%1$d", this verifies the same count of these strings are included in the other .strings file.
# 4. Verification to ensure that no values contain only "%" character, not "%%".

# Example) ruby ./scripts/localization/localizable_strings_checker.rb i18nLocalizableStringsExample

# https://github.com/rylev/apfel
require 'apfel'
require 'find'

SPECIAL_STRINGS = [
  "%%",
  "%s",
  "%1$s", 
  "%2$s", 
  "%3$s", 
  "%4$s", 
  "%@", 
  "%1$@", 
  "%2$@", 
  "%3$@", 
  "%4$@", 
  "%d",
  "%1$d",
  "%2$d",
  "%3$d",
  "%4$d",
  "%f",
  "%1$f",
  "%2$f",
  "%3$f",
  "%4$f",
]

def check_same_keys(ja_keys, other_keys)
  sorted_ja_keys = ja_keys.sort
  sorted_other_keys = other_keys.sort
  is_same_keys = sorted_ja_keys == sorted_other_keys
  puts "  Check the same keys of 'ja' exist in other languages: #{is_same_keys}."

  if !is_same_keys
    missing_keys = sorted_ja_keys - sorted_other_keys
    if missing_keys.length > 0
      puts "    These keys exists in only 'ja' strings file."
      missing_keys.each do |key|
        puts "      #{key}"
      end
    end
  end
  is_same_keys
end

def check_same_comments(ja_comments, other_comments)
  sorted_ja_comments = ja_comments.sort
  sorted_other_comments = other_comments.sort
  is_same_comments = sorted_ja_comments == sorted_other_comments
  puts "  Check the same comments of 'ja' exist in other languages: #{is_same_comments}."

  if !is_same_comments
    missing_comments = sorted_ja_comments - sorted_other_comments
    if missing_comments.length > 0
      puts "    These comments exists in only 'ja' strings file."
      missing_comments.each do |key|
        puts "      #{key}"
      end
    end
  end
  is_same_comments
end

def check_replace_strings(ja_key_values, other_key_values)
  puts "  If the values in 'ja' strings contain the replacable characters, check the other strings file have the same count of them."
  has_diff = false
  ja_key_values.each do |key_value|
    key = key_value.keys.first
    value = key_value.values.first

    # Extact the target strings
    regex = Regexp.union(SPECIAL_STRINGS.map { |str| Regexp.escape(str) })
    matches = value.scan(regex).uniq

    if matches.length > 0
      # Get other strings value of 'ja' key
      other_value = other_key_values.find { |hash| hash.key?(key) }&.[](key)
      # Get the target strings which does not exist in the other strings file
      missing_strings = matches.reject { |str| other_value.include?(str) }

      if missing_strings.length > 0
        has_diff = true
        puts "    key[#{key}] 's value does not have #{missing_strings}."
      end
    end
  end
  !has_diff
end

def check_single_percent_string(key_values)
  puts "  Check no values contain only '%' character."

  has_error = false

  key_values.each do |key_value|
    key = key_value.keys.first
    value = key_value.values.first

    has_single_percent = value.match(/(?<!%)%(?![%]|[@]|[d]|[s]|[f]|[[0-9]$@]|[[0-9]$d]|[[0-9]$s]|[[0-9]$f])/)
    if has_single_percent
      has_error = true
      puts "    key[#{key}] 's value have only '%' character."
    end
  end
  !has_error
end

unless ARGV.length < 2
  puts "Usage: ruby #{$0} <dir path includes xx.lproj>"
  exit 1
end

root_dir = ARGV[0]

# Load ja strings file
ja_path = "#{root_dir}/ja.lproj/Localizable.strings"
ja_file = Apfel.parse(ja_path)

puts "Loaded #{ja_path}, key counts: #{ja_file.keys.length}"

# Check ja strings contains only "%" character, not "%%"
has_single_percent = check_single_percent_string(ja_file.key_values)

# Check the other strings file
Find.find(root_dir) do |path|
  if path =~ /.*\.lproj\/Localizable.strings$/ && path !~ /ja\.lproj/
    other_file = Apfel.parse(path)
    puts "Loaded #{path}, key counts: #{other_file.keys.length}"

    # 1. Verification that the keys in 'ja' are also present in the other .strings files.
    is_same_keys = check_same_keys(ja_file.keys, other_file.keys)

    # 2. Verification that the comments in 'ja' are also present in the other .strings files.
    is_same_comments = check_same_comments(ja_file.comments, other_file.comments)

    # 3. If the values in 'ja' strings contain the replacable characters, this verifies the same count of these strings are included in the other .strings file.
    no_special_strings_diff = check_replace_strings(ja_file.key_values, other_file.key_values)

    # 4. Verification to ensure that no values contain only "%" character, not "%%".
    has_single_percent = check_single_percent_string(other_file.key_values)
 
    has_error = !is_same_keys || !is_same_comments || !no_special_strings_diff || !has_single_percent

    if has_error
      exit 1
    end

    puts "  No errors! Perfect!"
  end
end
