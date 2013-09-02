require 'rubygems'

puts "Load the module: use XBase"
require './main.rb'
@XBaseloaded=true
puts "ok 1"

puts "Load table test.dbf"
table=XBase::XBase.new("./test/test.dbf",:readonly=>true)
puts "ok 2"

break if table.nil?

puts "Read the records, one by one"
records_expected=['0:1:Record no 1:This is a memo for record no one::19960813',
	'1:2:No 2:This is a memo for record 2:1:19960814',
	'0:3:Message no 3:This is a memo for record 3:0:19960102'].join "\n"
#records = join "\n", map {
#	join ":", map { defined $_ ? $_ : "" } $table->get_record($_) }
#								( 0 .. 2 );
#records=(0..2).map{|i|(!table.get_record(i).nil? ? table.get_record(i) : "").join(":")}.join("\n")
#puts "Expected:\n#{records_expected}\nGot:\n#{records}\nnot " if records_expected!=records
#puts "ok 3"

#puts "Get record 0 as hash";
#hash_values_expected = 'nil, 19960813, 1, "Record no 1", "This is a memo for record no one", 0'
#hash = table.get_record_hash(0)
#hash_values = join ', ',
#	map { defined $_ ? ( /^\d+$/ ? $_ : qq["$_"] ) : 'undef' }
#					map { $hash{$_} } sort keys %hash;
#hash_values=hash.keys.sort
#puts "Expected:\n\@hash{ qw( @{[sort keys %hash]} ) } =\n ($hash_values_expected)\nGot:\n$hash_values\nnot " if hash_values_expected!=hash_values
#puts "ok 4"

print "Load the table rooms\n";
rooms = XBase::XBase.new("./test/rooms.dbf",:readonly=>true)
print "ok 5\n"

#print "Check the records using read_record\n";
#$records_expected = join '', <DATA>;
#$records = join "\n", (map { join ':', map { defined $_ ? $_ : '' }
#			$rooms->get_record($_) }
#				(0 .. $rooms->last_record())), '';
#if ($records_expected ne $records)
#	{ print "Expected:\n$records_expected\nGot:\n$records\nnot "; }
# print "ok 6\n";

print "Check the records using get_all_records\n"
all_records = rooms.get_all_records(['ROOMNAME', 'FACILITY'])
if all_records.nil?
#  { print $rooms->errstr, "not "; }
  puts "error rooms"
else
  records=[all_records.map{|i|[0,i].join(':')},''].join("\n")
	#records = join "\n", (map { join ':', 0, @$_; } @$all_records), '';
  print "Expected:\n#{records_expected}\nGot:\n#{records}\nnot " if records_expected!=records
end
print "ok 7\n"

print "Check if reading record that doesn't exist will produce error\n"
result = table.get_record(3)
print "not " if !result.nil?
print "ok 8\n"

#print "Check error message\n"
#my $errstr = $table->errstr();
#my $errstr_expected = "Can't read record 3, there is not so many of them\n";
#if ($errstr ne $errstr_expected)
#	{ print "Expected: $errstr_expected\nGot: $errstr\nnot "; }
#print "ok 9\n";

print <<EOF;
If all tests in this file passed, reading of the dbf data seems correct,
including the dbt memo file.
EOF

true