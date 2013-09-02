require 'rubygems'
puts "Load the module: use XBase"

require './main.rb'
@XBaseloaded=true
puts "ok 1"
puts 'This is XBase version $XBase::VERSION\n'

puts "Create the new XBase object, load the data from table test.dbf\n"
table=XBase::XBase.new("./test/test.dbf",:readonly=>true)
puts "Error1" if table.nil?
break if table.nil?
puts "ok 2"

puts "Now, look into the object and check, if it has been filled OK"
info=sprintf "Version: 0x%02x, last record: %d, last field: %d",
             table.version, table.last_record, table.last_field
info_expect='Version: 0x83, last record: 2, last field: 4'
puts "Expected:\n#{info_expect}\nGot:\n#{info}\nnot " if info!=info_expect
puts "ok 3"

puts "Check the field names"
names=table.field_names.join ' '
names_expect='ID MSG NOTE BOOLEAN DATES'
puts "Expected: #{names_expect}\nGot: #{names}\nnot " unless names==names_expect
puts "ok 4"

#puts "Get verbose header info (using header_info)"
#info = table.get_header_info
#info_expect = join '', <DATA>;
#puts "Expected: #{info_expect}\nGot: #{info}\nnot " if info!=info_expect
#print "ok 5"

#puts "Check if loading table that doesn't exist will produce error"
#badtable = XBase::XBase.new("nonexistent.dbf",:readonly=>true)
#puts 'not ' if !badtable.nil?
#print "ok 6"

#print "Check the returned error message\n";
#my $errstr = XBase->errstr();
#my $errstr_expect = 'Error opening file nonexistent.dbf:';
#if (index($errstr, $errstr_expect) != 0)
#	{ print "Expected: $errstr_expect\nGot: $errstr\nnot "; }
#print "ok 7\n";

table.close

#puts "Load table without specifying the .dbf suffix"
#table = XBase::XBase.new("./test/test",:readonly=>true)
#print "not " if table.nil?
#print "ok 8"

puts <<EOF
If all tests in this file passed, the module works to such an extend
that new XBase loads the table and correctly parses the information in
the file header.
EOF

puts "Now reload with recompute_lastrecno"
table = XBase::XBase.new("./test/test.dbf", :recompute_lastrecno => 1,:readonly=>true)
#print XBase->errstr(), 'not ' unless defined $table;
puts "ok 9"

last_record = table.last_record
puts "recompute_lastrecno computed #{last_record} records\nnot " if last_record != 2
puts "ok 10"

