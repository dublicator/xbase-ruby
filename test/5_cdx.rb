require "rubygems"

print "Load the module: use XBase\n"

require './main.rb'
@XBaseloaded = true
print "ok 1\n"

print "Open table test/rooms\n"
table = XBase::XBase.new("./test/rooms.dbf",:readonly=>true) or begin
	print "not ok 2\n"
	break
end
print "ok 2\n"

print "prepare_select_with_index on ROOMNAME\n"
cur = table.prepare_select_with_index([ "./test/rooms.cdx", 'ROOMNAME' ]) or print "error load cdx"
print "ok 3\n"

my $result = ''
print "Fetch all data\n"
while (data = cur.fetch)
	print "#{data}\n"
  result = result+"#{data}\n"
end

expected_result = ''
#while (defined($line = <DATA>))
#	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; } 