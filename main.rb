require 'rubygems'
require 'iconv'
#require 'dbi'

module XBase
	# Base input output module for XBase suite
	class Base
		def fh
			@fh
		end

		def initialize(file,opts)
			 SEEK_VIA_READ(false)
			 self.open(file,opts)
		 end

		# Seek to absolute position
		def seek_to_seek(offset)
			unless @fh
				raise "Cannot seek on unopened file\n"
			end
			@fh.seek(offset)
			true
		 end

		def SEEK_VIA_READ(arg)
			  if arg
				  alias :seek_to :seek_to_read
				  @SEEK_VIA_READ=true
			  else
				  alias :seek_to :seek_to_seek
				  @SEEK_VIA_READ=false
			  end
		 end

		# Open the specified file. Use the read_header to load the header data
		def open(*args)
			options={}
			options[:name]=args.shift if !args[0].nil? and args[0].class==String
			@openoptions=options.merge(args[0]) unless @openoptions!=nil
			options=options.merge(args[0])
			if @fh!=nil
				self.close
			end
			external_fh=false
			if options[:name]=='-'
			else
				ok=true
				if !options[:readonly]
					fh=File.new(options[:name],'w+')
					rw=true
				else
					fh=File.new(options[:name],'r+')
					rw=false
					ok=true
				end
				if !ok
					raise "Error opening file #{options[:name]}: $!\n"
				end
			end
			@tell=0 if @SEEK_VIA_READ
			fh.flush
			fh.binmode unless external_fh
			@fh,@filename,@rw=fh,options[:name],rw
			self.read_header options
		end

		# Read from the filehandle
		def read(*args)
			fh=@fh or return
			if args[1]!=nil
				fh.seek(args[1],IO::SEEK_CUR)
			end
			result=fh.read(args[0])
			if result!=nil and @tell!=nil
				@tell+=result
			end
			result
		end

		# Tell the position
		def tell
			if @tell!=nil
				return @tell
			end
			return @fh.tell
		end

		# Read the record of given number. The second parameter is the length of
		# the record to read. It can be undefined, meaning read the whole record
		# and it can be negative, meaning at most the length
		def read_record(*args)
			num,in_length=args
			if num.nil?
				raise "Number of the record must be defined when reading it\n"
			end
			if self.last_record>0 and num>self.last_record
				puts "Can't read record #{num}, there is not so many of them\n"
			end
			if in_length.nil?
				in_length=@record_len
			end
			if in_length<0
				in_length=-@record_len
			end
			offset=self.get_record_offset(num)
			return if offset.nil?
			self.read_from(offset,in_length)
		end

		# Compute the offset of the record
		def get_record_offset(num)
			header_len,record_len=@header_len,@record_len
			unless (header_len!=nil and record_len!=nil)
				raise "Header and record lengths not known in get_record_offset\n"
			end
			unless num!=nil
				raise "Number of the record must be specified in get_record_offset\n"
			end
			return header_len+num*record_len
		end

		def read_from(offset,in_length)
			if offset==nil
				raise "Offset to read from must be specified\n"
			end
			self.seek_to(offset) or return
			length=in_length
			length=-length if length<0
			buffer=self.read(length)
			read=buffer.length
			if read==0 or (in_length>0 and read!=in_length)
				raise "Error reading #{in_length} bytes from #{@filename}\n"
			end
			buffer
		end

		# Close the file
		def close
			if @fh==nil
				raise "Can't close file that is not opened\n"
			end
			@fh.close
			@fh=nil
			true
		end

		def self.drop(filename)
			 raise "Not implemented yet"
			 if filename!=nil
			 end
		 end

		# Drop (unlink) the file
		def drop
			if !@filename.nil?
				filename=@filename
				self.close if !@fh.nil?
				if !FileUtils.rm(filename)
					raise "Error unlinking file #{filename}: $!\n"
					return
				end
			end
			return true
		end

		# Create new file
		def create_file(args)
			filename,perms=args
			if filename.nil?
				raise "Name has to be specified when creating new file\n"
			end
			if File.file?(filename)
				raise "File #{filename} already exists\n"
			end
			perms=0644 unless !perms.nil?
			fh=File.new(filename,'w',perms) or return
			fh.binmode
			@fh,@filename,@rw=fh,filename,true
			#return self
		end

		# Seek to start of the record
		def seek_to_record(num)
			offset=self.get_record_offset(num)
			return if offset==nil
			self.seek_to(offset)
		end

		def seek_to_read(offset)
			unless @fh!=nil
				raise "Cannot seek on unopened file\n"
			end
			tell=self.tell
			if offset<tell
				raise "Cannot seek backwards without using seek (#{offset} < #{tell})\n"
			end
			if offset>tell
				udef=self.read(offset-tell)
				tell=self.tell
			end
			if tell!=offset
				raise "Some error occured during read-seek: $!\n"
			end
			true
		end

		# Write the given record
		def write_record(num,args)
			offset=self.get_record_offset(num)
			return if offset==nil
			w=self.write_to(offset,args)
			return if w==nil
			num==0 ? '0E0' :num
		end

		# Write data directly to offset
		def write_to(offset,args)
			if !@rw
				raise "The file #{@filename} is not writable\n"
			end
			self.seek_to(offset) or return
			@fh.print(args) or raise "Error writing to offset #{offset} in file #{@filename}: $!\n"
			offset==0 ? '0E0' : offset
		end

		def _locksh(fh)
			fh.flock(1)
		end

		def _lockex(fh)
			fh.flock(2)
		end

		def _unlock(fh)
			fh.flock(8)
		end

		def locksh
		_locksh(@fh)
	end

		def lockex
		_lockex(@fh)
	end

		def unlock
		_unlock(@fh)
	end
	end
end

module XBase
	class Index < Base
		def initialize(file,*args)
			opts=args
				#@xbase=xbase
				ext=file.scan(/\.(...)$/).first.last.downcase
				if ext=='sdbm' or ext=='pag' or ext=='dir'
				end
				if ext=='cdx'
					object=Cdx.new(file,opts[0])
				end
				return object if object!=nil
				raise "Error loading index: unknown extension\n"
				return
			end

		def record_len
			@record_len
		end

		def last_record
				@total_pages
			end

		def get_key_val_left(num)
				printkey=@keys[num]
				#printkey=printkey.scan(/\s+\n/)
				#printkey=printkey.scan("\000/\\0")#\\g
				return nil if (@keys==nil or @keys[num]==nil) and (@values==nil or @values[num]==nil) and (@lefts==nil or @lefts[num]==nil)
				return [@keys[num],@values[num],@lefts==nil ? nil : @lefts[num]] if num<=@keys.length
				return nil
			end

		def prepare_select
			@level=nil
			@pages=nil
			@rows=nil
			true
		end

		def fetch
			level, page, row, key, val, left=nil
			while val.nil?
				level=@level
				if level.nil?
					level=@level=0
					page=self.get_record(@start_page)
					if page.nil?
						raise "Index corrupt: no root page @#{start_page}\n"
					end
					@pages=[page]
					@rows=[]
				end

				page=@pages[level]
				if page==nil
					raise "Index corrupt: page for level #{level} lost in normal course\n"
				end
				row=@rows[level]
				if row.nil?
					row=@rows[level]=0
				else
					row+=1
					@rows[level]= row
				end
				key,val,left=page.get_key_val_left(row)
				if !left.nil?
					level+=1
					oldpage=page
					page=self.get_record(left)
					if page.nil?
						raise "Index corrupt: no page #{left}, ref'd from #{oldpage}, row #{row}, level #{level}\n"
					end
					@pages[level]=page
					@rows[level]=nil
					@level=level
					val=nil
					next
				end
				if val!=nil
					return key,val
				else
					level-=1
					@level= level
					return nil,nil if level<0
					page=@pages[level]
					if page==nil
						raise "Index corrupt: page for level #{level} lost when backtracking\n"
					end
					row=@rows[level]
					backkey,backval,backleft=page.get_key_val_left(row)
					if @lastkeyisjustoverflow==nil and backleft!=nil and backval!=nil
						return backkey,backval
					end
				end
			end
			return nil,nil
		end

		def get_record(num)
			return @pages_cache[num] if @pages_cache!=nil and @pages_cache[num]!=nil
			page=Page.new self,num
			if page!=nil
				@pages_cache[num]=page
			end
			page
		end

		def key_length
			@key_length
		end

		def key_record_length
			@key_record_length
		end

		def key_type
			@key_type
		end

#		def prepare_select_eq(*args)
#			eq,recno=args
#			self.prepare_select
#			left=@start_page
#			level=0
#			parent=nil
#			numdate=(@key_type!=0||@key_type!=nil)
#			while true
#				page=self.get_record(left)
#				if page==nil
#					raise "Index corrupt: no page #{left} for level #{level}\n"
#				end
#				row=0
#				while arr=page.get_key_val_left(row)
#					key,val,newleft=arr
#					left=newleft
#					if key==nil
#						break
#					end
#					if numdate == 1 ? key >= eq : key >= eq
#						break
#					end
#					row+=1
#				end
#				@pages[level]=page
#				@rows[level]=row
#				if left==nil
#					@rows[level]=row ? row-1 : nil
#					@level=level
#					break
#				end
#				page.parent=parent[num] if parent!=nil
#				parent=page
#				level+=1
#			end
#			if recno!=nil
#				key,val=self.fetch_current
#				while val!=nil
#					break if numdate ? key>eq : key>=eq
#					break if val==recno
#					key,val=self.fetch
#				end
#			end
#			true
#		end

		def tags
			@tags if @tags!=nil
		end

		def fetch_current
			level=@level
			page=@pages[level]
			row=@rows[level]
			key,val,left=page.get_key_val_left(row)
			return key,val
		end

		def num_keys
			@keys.length
		end
	end
end

module XBase
	class Cdx < Index
		def tag=(value)
			@tag=value
		end

		def initialize(file,*args)
			#@xbase=xbase
			@pages_cache=[]
			@tags=[]
			self.class.superclass.instance_method(:open).bind(self).call(file,args[0])
		end

		def read_header(*opts)
			opts=opts[0]
			#opts[:tag]=opts[:tag]
			header=@fh.read(1024)
			raise "Error reading header of #{@filename}: $!\n" if header.length!=1024
			@start_page, @start_free_list, @total_pages,
					@key_length, @index_options, @index_signature,
					@sort_order, @total_expr_length, @for_expression_length,
					@key_expression_length,
					@key_string=header.unpack('VVNv CC @502 vvv @510 v @512 a512')
			@total_pages=-1
			@key_string=@for_string#=@key_string.scan(/^([^\000]*)\000([^\000]*)/).first.last   !!!
			@key_record_length=@key_length+4
			@record_len=512
			@start_page/=@record_len
			@start_free_list!=@record_len
			@header_len=0
			@key_type=0
			if @tag.nil?
				self.prepare_select
				while tag=self.fetch[0]
					@tags.push tag
				end
      end
			if opts[:tag]!=nil
				self.prepare_select_eq opts[:tag]
				foundkey,value=self.fetch
				if foundkey==nil
					raise "No tag #{opts[:tag]} found in index file #{@filename}.\n"
				end
				subidx=self
				subidx.fh.seek(value,0)
				subidx.tag=opts[:tag]
				subidx.read_header
			end
			self
		end

		def last_record
			@total_pages
		end

 		def prepare_select_eq(*args)
			eq,recno=args
			self.prepare_select
			left=@start_page
			level=0
			parent=nil
			numdate=@key_type!=0 ? true : false
			while true
				page=self.get_record(left)
				if page==nil
					raise "Index corrupt: no page #{left} for level #{level}\n"
				end
				row=0
				while arr=page.get_key_val_left(row)
					break if arr.nil? or arr.size==0
					key,val,newleft=arr
					left=newleft
					if key.nil?
						break
					end
					if numdate ? key >= eq : (key <=> eq.to_s)!=nil and (key <=> eq.to_s)>0
						break
					end
					row+=1
				end
				@pages=[] if @pages==nil
				@rows=[] if @rows==nil
				@pages[level]=page
				@rows[level]=row
				if left==nil
					@rows[level]=row!=0 ? row-1 : nil
					@level=level
					break
				end
				page.parent=parent[num] if parent!=nil
				parent=page
				level+=1
			end
			if recno!=nil
				key,val=self.fetch_current
				while val!=nil
					break if numdate ? key>eq : key>=eq
					break if val==recno
					key,val=self.fetch
				end
			end
			true
		end
	end
end

module XBase
	class Page < Cdx
		def initialize(indexfile,num)
			data=indexfile.read_record(num) or return
			origdata=data
			attributes,noentries,left_brother,right_brother=data.unpack 'vvVV'
			keylength=indexfile.key_length
			keyreclength=indexfile.key_record_length
			numdate=indexfile.key_type
			keys,values,lefts=[],[],nil
			if attributes&2!=0
				free_space,recno_mask,duplicate_count_mask,trailing_count_mask, recno_count,duplicate_count,
						trailing_count, holding_recno=data.unpack '@12 vVCCCCCC'
				@recno_count,@duplicate_count,@trailing_count,@holding_recno=
						recno_count,duplicate_count,trailing_count,holding_recno
				prevkeyval=''
				(0..noentries-1).each do |i|
					one_item=data[24+i*holding_recno,holding_recno]+("\0" * 4)
					numeric_one_item=one_item.unpack('V').first
					recno=numeric_one_item & recno_mask
					bytes_of_recno=recno_count/8
					one_item=one_item[bytes_of_recno..one_item.length-1]
					numeric_one_item=one_item.unpack('V').first
					numeric_one_item >>= recno_count-8*bytes_of_recno
					dupl=numeric_one_item & duplicate_count_mask
					numeric_one_item >>= duplicate_count
					trail=numeric_one_item&trailing_count_mask
					getlength=keylength-trail-dupl
					key=prevkeyval[0,dupl]
					(key = key + data[-getlength,getlength]) if getlength!=0
					key = key + ("\000" * trail)
					data[-getlength,getlength]='' if getlength!=0
					prevkeyval=key
					if numdate!=0
						if 0x80 & key.unpack('C')
							key[0,1]&="\177"
						else
							key= ~key
						end
						if keylength==8
							key=key.reverse unless @BIGEND
							key=key.unpack 'd'
						else
							key=key.unpack 'N'
						end
						if numdate==2 and (key!=nil and key!=0)
							 #key=sprintf "%04d%02d%02d",!!!inverse_julian_day(key)
						end
					else
						key[-trail,trail]='' if trail!=0
					end
					keys.push key
					values.push recno
				end
			else
				(0..noentries-1).each do |i|
					offset=12+i*(keylength+8)
					key,recno,page=data.unpack("@#{offset} a#{keylength} NN")
					if numdate!=0
						if 0x80&key.unpack('C')!=0
							key[0,1]&="\177"
						else
							key= ~key
						end
						if keylength==8
							key=key.reverse unless @BIGEND
							key=key.unpack 'd'
						else
							key=key.unpack 'N'
						end
						if numdate==2 and key!=0
							#$key = sprintf "%04d%02d%02d",Time::JulianDay::inverse_julian_day($key);
						end
					else
						key=key.scan(/\000+"\n"/).first.last#$/
					end
					keys.push key
					values.push value
					lefts=[] unless lefts!=nil
					lefts.push page/512
				end
				@last_key_is_just_overflow=1
			end
			@keys,@values,@num,@key_length,@lefts,@indexfile,@attributes,@left_brother,@right_brother=
					keys,values,num,keylength,lefts,indexfile,attributes,left_brother,right_brother
			#_self=Pag
			outdata=self.prepare_scalar_for_write
			if 0 and outdata!=origdata
				#puts "I won't be able to write this page back.\n",
				 #    outdata.unpack("H*"),"\n ++\n",
			  #     origdata.unpack("H*"),"\n"
			else

			end
		end

		def prepare_scalar_for_write
			attributes,noentries,left_brother,right_brother=@attributes,@keys.length,@left_brother,@right_brother
			data=[attributes,noentries,left_brother,right_brother].pack('vvVV')
			indexfile=@indexfile
			numdate=indexfile.key_type
			record_len=indexfile.record_len
			keylength=@key_length
			if attributes&2!=0
				recno_count,duplicate_count,trailing_count,holding_recno=[16,4,4,3]
				if @recno_count!=nil
					recno_count,duplicate_count,trailing_count,holding_recno=
							@recno_count,@duplicate_count,@trailing_count,@holding_recno
				end
				recno_mask,duplicate_mask,trailing_mask=[2**recno_count-1,2**duplicate_count-1,2**trailing_count-1]
				recno_data=''
				keys_string=''
				prevkey=''
				row=0
				@keys.each do |key|
					dupl=0
					out=key
					if numdate!=0
						if keylength==8
							out=out.pack('d')
							out=out.reverse unless @BIGEND
						else
							out=out.pack 'N'
						end
						unless (0x80&out.unpack('C'))
							out[0,1]|="\200"
						else
							out= ~out
						end
					end
					(0..out.length-1).each do |i|
						unless (out[i,1]==prevkey[i,1])
							break
						end
						dupl+=1
					end
					trail=keylength-out.length
					while out[-1,1]=="\000"
						out=out[0,out.length-1]
						trail+=1
					end
					keys_string="#{out[dupl,out.length]}#{keys_string}" #substr(out,dupl)
					numdata=((((trail & trailing_mask) << duplicate_count) | (dupl & duplicate_mask)) << recno_count) | (@values[row] & recno_mask)
					recno_data=recno_data+[numdata].pack('V')[0,holding_recno]
					prevkey=out
					row+=1
				end
				data=data+[(record_len - recno_data.length - keys_string.length- 24),
				           recno_mask, duplicate_mask,trailing_mask, recno_count,
				           duplicate_count,trailing_count, holding_recno].pack('vVCCCCCC')
				data=data+recno_data
				data=data+"\000" * (record_len-data.length-keys_string.length)
				data=data+keys_string
			else
				row=0
				@keys.each do |key|
					out=key
					if numdate
						if keylength==8
							out=out.pack('d')
							out=out.reverse unless @BIGEND
						else
							out=out.pack('N')
						end
						unless (0x80&out.unpack('C'))!=0
							out[0,1]!="\200"
						else
							out= ~out
						end
					end
					data=data+[out,@values[row],@lefts[row]*512].pack("a#{keylength} NN")
					row+=1
				end
				data=data+"\000"*(record_len-data.length)
			end
			data
		end

		def get_parent_page
			parent_num=self.get_parent_page_num or return
			indexfile=@indexfile
			return indexfile.get_record(parent_num)
		end
	end
end

module XBase
	class Cursor < Base
		def initialize(*args)
			@xbase,@recno,@fieldnums,@fieldnames=args
		end

		def fetch
			xbase, recno, fieldnums, fieldnames=@xbase,@recno,@fieldnums,@fieldnames
			if recno!=nil
				recno+=1
			else
				recno=0
			end
			lasrec=xbase.last_record
			while recno<=lasrec
				result=xbase.get_record_nf(recno,fieldnums)
				del=result.shift
				if result.length>0 and !del
					@recno=recno
					return result
				end
				recno+=1
			end
			return
		end

		def fetch_hashref
			data=self.fetch
			hashref={}
			if data!=nil
				hashref[@hashnames]=data
				return hashref
			end
			return
		end

		def last_fetched
			#shift->[1]
		end

		def table
			#shift->[0]
		end

		def names
			#shift->[3]
		end

		def rewind
			#shift[1]=nil
			'0E0'
		end

		def attach_index
			include Index
		end
	end
end

module XBase
	class IndexCursor < Cursor
			def fetch
				xbase,recno,fieldnums,fieldnames,index=@xbase,@recno,@fieldnums,@fieldnames,@index
				p=true
				while val=index.fetch[1]
					del,result=xbase.get_record_nf(val-1,fieldnums)
					unless del
						@val=val
						return result
					end
				end
				return
			end

			def last_fetched
				@val-1
			end

			def find_eq(val)
				@index.prepare_select_eq(val)
			end

			def initialize(xbase,recno,fieldnums,fieldnames,index)
				@xbase,@recno,@fieldnums,@fieldnames,@index=xbase,recno,fieldnums,fieldnames,index
			end

			def index
				@index
			end
		end
end

module XBase
		class XBase < Base
			def last_record
				@num_rec-1
			end

			def open(*args)
				options={}
				if args.length%2
					options[:name]=args.shift
				end
				@openoptions=options.merge(args[0])
				locoptions={}
				locoptions[:name],locoptions[:readonly],locoptions[:ignorememo],locoptions[:fh]=
						@openoptions[:name],@openoptions[:readonly],@openoptions[:ignorememo],@openoptions[:fh]
				return self.class.superclass.instance_method(:open).bind(self).call(locoptions)
			end

			def read_header(*opts)
				fh=@fh
				header=self.read(32)
				#p header
				if header.length!=32
					raise "Error reading header of #{@filename}: $!\n"
				end
				@version,@last_update,@num_rec,@header_len,@record_len,@encrypted=header.unpack('Ca3Vvv@15a1')
				header_len=@header_len
				names,types,lengths,decimals=[],[],[],[]
				unpacks,readproc,writeproc=[],[],[]
				lastoffset=1
				while self.tell<header_len-1
					field_def=self.read(1)
					#p field_def
					break if field_def=="\r"
					field_def=field_def+self.read(31)
					read=field_def.length
					if read!=32
						raise "Error reading field description: $!\n"
					end
					name,type,length,decimal=field_def.unpack('A11a1 @16CC')
					if type=='C'
						if decimal!=0 and !@openoptions['nolongchars']
							length+=256*decimal
							decimal=0
						end
						rproc=proc do |value|
							if @ChopBlanks
								#value=value.scan("\s+#{$/}")
							end
							return value==''?nil:Iconv.iconv('UTF-8','866',value).first.strip
						end
						wproc=proc do |value|
							sprintf '%-*.*s', length, length,(value!=nil ? value : '')
						end
					end
					#name=name.scan("[\000 ].*#{$/}").first.last
					name.upcase!
					names.push name
					types.push type
					lengths.push length
					decimals.push decimal
					unpacks.push "@#{lastoffset}a#{length}"
					readproc.push rproc
					writeproc.push wproc
					lastoffset+=length
				end
				if lastoffset>@record_len and !@openoptions['nolongchars']
					self.seek_to(0)
					@openoptions['nolongchars']=1
					return self.read_header
				end
				if lastoffset!=@record_len and @openoptions['ignorebadheader']==nil
					 raise "Mismatch in header of #{@filename}: record_len #{@record_len} but offset #{lastoffset}\n"
				end
				if @openoptions['recompute_lastrecno']
					#
				end
				hashnames=names.to_h
				@field_names, @field_types ,@field_lengths ,@field_decimals,
						@hash_names ,@last_field ,@field_unpacks,
						@field_rproc ,@field_wproc ,@ChopBlanks=names, types, lengths, decimals,
									hashnames, names.length-1, unpacks,
									readproc, writeproc, @CLEARNULLS
				return true
			end

			def get_record(num,*args)
				self.get_record_nf(num,args.map{|i|self.field_name_to_num(i)})
			end

			def field_name_to_num(name)
				@hash_names[name.upcase]
			end

			def get_record_nf(num,fieldnums)
				data=self.read_record(num) or return
				if fieldnums==nil or fieldnums.length==0
					fieldnums=(0..self.last_field)
				end
				unpack=['@0a1'].concat fieldnums.map{|value|e=@field_unpacks[value] if value!=nil;e!=nil ? e : '@0a0'}
				unpack=unpack.join(' ')
				rproc=@field_rproc
				fns=fieldnums.map{|i|i!=nil and rproc[i]!=nil ? rproc[i] : proc{|value| nil}}
				out=data.unpack(unpack)
				out[0]=read_deleted(out[0])
				(1..out.length-1).each{|i|out[i]=fns[i-1].call(out[i])}
				out
			end

			def read_deleted(value)
				if value=='*'
					return true
				elsif value==' '
					return false
				end
				nil
			end

			def prepare_select(*args)
				fieldnames=*args
				if fieldnames==nil or fieldnames.length==0
					fieldnames=self.field_names
				end
				fieldnums=fieldnames.map{|value|self.field_name_to_num(value)}
				return Cursor.new(self,nil,fieldnums,fieldnames)
			end

			def prepare_select_with_index(f,*args)
				if f.class==Array
					tagopts={:tag=>f[1]}
					if !f[2].nil?
						tagopts.push :type=>f[2]
					end
					file=f[0]
				end
				fieldnames=args
				if fieldnames==nil or fieldnames.length==0
					fieldnames=self.field_names
				end
				fieldnums=fieldnames.map{|i|self.field_name_to_num(i)}
				#index=Index.new(file,true,self)
				index=Index.new(file,{:dbf=>self,:readonly=>true}.merge(tagopts))
				index.prepare_select
				return IndexCursor.new self,nil,fieldnums,fieldnames,index
			end

			def field_names
				@field_names
			end

			def init_memo_field
				return @memo if @memo!=nil
				options={'dbf_version'=>@version,'memosep'=>@memosep}
				if @memofile!=nil
					return Memo.new(@memofile,options)
				end
				['dbt', 'DBT', 'fpt', 'FPT', 'smt', 'SMT'].each do |i|
					memoname=@filename
					raise "Not implemented yet"
				end
				return
			end

			def close
				if @memo!=nil
					@memo.close
					@memo=nil
				end
				self.class.superclass.instance_method(:close).bind(self).call
			end

			def version
				@version
			end

			def last_field
				@last_field
			end

			def field_names
				@field_names
			end

			def field_types
				@field_types
			end

			def field_lengths
				@field_lengths
			end

			def field_decimals
				@field_decimals
			end

			def field_type(name)
				num=self.field_name_to_num(name)
				return if num==nil
				self.field_types[num]
			end

			def field_length(name)
				num=self.field_name_to_num(name)
				return if num==nil
				self.field_lengths[num]
			end

			def field_decimal(name)
				num=self.field_name_to_num(name)
				return if num==nil
				self.field_decimals[num]
			end

			def get_header_info
				hexversion=sprintf '0x%02x', self.version
				longversion = self.get_version_info['string']
				printdate = self.get_last_change
				numfields = self.last_field() + 1
				result="
Filename:	#{@filename}
Version:	#{hexversion} (#{longversion})
Num of records:	#{@num_rec}
Header length:	#{@header_len}
Record length:	#{@record_len}
Last change:	#{printdate}
Num fields:	#{numfields}
Field info:
Num	Name		Type	Len	Decimal
"
				fields=(0..self.last_field).map{|i|self.get_field_info(i)}
				return result+fields
			end

			def get_field_info(num)
				sprintf "%d.\t%-16.16s%-8.8s%-8.8s%s\n", num + 1,[@field_names,@field_types,@field_lengths,@field_decimals].map{|i|i[num]}
			end

			def get_last_change
				date=@last_update
				year,mon,day=date.unpack('C3')
				year+=(year>=70) ? 1900 : 2000
				return "#{year}/#{mon}/#{day}"
			end

			def get_version_info
				version=@version
				result={}
				result['vbits']=version&0x07
				if version==0x30 or version==0xf5
					result['vbits']=5
					result['foxpro']=1
				elsif version&0x08
					result['vbits']=4
					result['memo']=1
				elsif version&0x80
					result['dbt']=1
				end
				string="ver. #{result['vbits']}"
				if result['foxpro']!=nil
					string=string+" (FoxPro)"
				end
				if result['memo']!=nil
					string=string+" with memo file"
				elsif result['dbt']!=nil
					string=string+" with DBT file"
				end
				result['string']=string
				result
			end

			def dump_records(*args)
				options={'rs'=>"\n",'fs'=>':','undef'=>''}
				inoptions=args
				inoptions.each do |key,val|
					value=val
					outkey=key.downcase
					outkey=outkey.scan(/[^a-z]//g).first.last
					options[outkey]=value
				end
				rs,fs,udef,fields,table=options['rs'],options['fs'],options['undef'],options['fields'],options['table']
				if table!=nil
					raise "Not implemented yet"
				end
				_fields=[]
				unknown_fields=[]
				if fields!=nil
					if fields.class==Array
						_fields=fields
					else
						_fields=fields.split /\s* \s*/
						i=0
						while i<_fields.length
							if self.field_name_to_num(fields[i])
								i+=1
							elsif fields[i]=~/^(.*)-(.*)/
								allfields=self.field_names
								#start,_end=$1,$2
								if start==''
									start=allfields[0]
								end
								if _end==''
									_end=allfields[allfields.length-1]
								end
								start_num=self.field_name_to_num(start)
								end_num=self.field_name_to_num(_end)
								if start!='' and start_num==nil
									unknown_fields.push start
								end
								if _end!+'' and end_num==nil
									unknown_fields.push _end
								end
								unless(start!=nil and _end!=nil)
									start=0
									_end=-1
								end

								_fields.splice i,1,allfields[start_num..end_num]
							else
								unknown_fields.push fields[i]
								i+=1
							end
						end
					end
				end
				if unknown_fields.length>0
					raise "There have been unknown fields `#{unknown_fields}' specified.\n"
				end
				cursor=self.prepare_select(_fields)
				if table!=nil
					raise "Not implemented yet"
				else
					while record=cursor.fetch
						puts record.map{|i|i!=nil ? i : nil}.join fs+rs
					end
				end
				true
			end

			def get_record_hash(num)
				list=self.get_record(num) or return
				hash={'DELETED'=>list.shift}
				hash[*self.field_names]=list#check
				hash
			end

			def get_all_records(args)
				cursor=self.prepare_select(args)
				result=[]
				while record=cursor.fetch
					result.push record#[record]
				end
				result
			end

			def set_record(num,data)
				wproc=@field_wproc
				if @attached_index_colums!=nil
					nfs=@attached_index_colums.keys
					del,old_data=self.get_record_nf(num,nfs)
					nfs.each do |nf|
						if old_data[nf]!=data[nf]
							@attached_index_colums[nf].each do |idx|
								idx.delete(old_data[nf],num+1)
								idx.insert(data[nf],num+1)
							end
						end
					end
				end
				(0..wproc.length-1).each do |i|
					data[i]=wproc[i].call(data[i])
				end
				data.unshift ' '
				self.write_record num,data
			end

			def set_record_hash(num,data)
				self.set_record(num,self.field_names.map{|i|data[i]})
			end

			def update_record_hash(num)
				olddata=self.get_record_hash(num)
				return unless olddata!=nil
				self.set_record_hash(num,olddata)
			end

			def write_record(num,args)
				ret=self.class.superclass.instance_method(:write_record).bind(self).call(num,args) or return
				if num>self.last_record
					self.class.superclass.instance_method(:write_record).bind(self).call(num+1,"\x1a")
					self.update_last_record(num) or return
				end
				self.update_last_change or return
				ret
			end

			def delete_record(num)
				self.write_record(num,"*")
			end

			def undelete_record(num)
				self.write_record(num," ")
			end

			def update_last_change
				return true if @updated_today!=nil
				now=Time.now
				y,m,d=now.year,now.month,now.day
				m+=1
				y-=100 if y>=100
				self.write_to(1,[y,m,d].pack("C3"))
				@updated_today=true
			end

			def update_last_record(last)
				last+=last
				self.write_to(4,[last].pack("V"))
				@num_rec=last
			end

			def create(args)
				options=args
				version=options['version']
				if version==nil
					if options['memofile']!=nil and options['memofile']=~/\.fpt$/i
						version=0xf5
					else
						version=3
					end
				end
				['field_names','field_types','field_lengths','field_decimals'].each do |key|
					if options[key]==nil
						raise "Tag #{key} must be specified when creating new table\n"
					end
				end
				needmemo=0
				fieldspack=''
				record_len=1
				(0..options['field_names'].length-1).each do |i|
					name=options['field_names'][i].upcase
					name="FIELD#{i}" unless name!=nil
					name=name+"\0"
					type=options['field_types'][i]
					type='C' if type==nil
					length=options['field_lengths'][i]
					decimal=options['field_decimals'][i]
					if length==nil
						if type=='C'
							length=64
						elsif type=~ /^[TD]$/
							length=8
						elsif type=~/^[NF]$/
							length=8
						end
					end
					if type=~/^[MBGP]$/
						lenght=1
						decimal=0
					elsif type=='L'
						length=1
						decimal=0
					elsif type=='Y'
						length=8
						decimal=4
					end
					if decimal==nil
						decimal=0
					end
					record_len+=lenght
					offset=record_len
					if type=='C'
						decimal=length/256
						length%=256
					end
					fieldspack=fieldspack+[name,type,offset,length,decimal,0,0,0,0,'',0].pack('a11a1VCCvCvCa7C')
					if type=='M'
						needmemo=1
						version|=0x80 if version!=0x30
					end
				end
				fieldspack=fieldspack+"\x0d"

				options['codepage']+=0
				header=[version,0,0,0,0,(32+fieldspack.length),record_len,0,0,0,'',0,options['codepage'],0]
				header=header+fieldspack
				header=header+"\x1a"

				tmp=self.class.new newname,false
				basename=options['name']
				basename=basename.scan(/\.dbf\n/i).first.last
				newname=options['name']
				if newname!=nil and !newname=~/\.dbf$/
					newname=newname+'.dbf'
				end
				tmp.create_file(newname,0700) or return
				tmp.write_to(0,header) or return
				tmp.update_last_change
				tmp.close

				if needmemo
					dbtname=options['memofile']
					if dbtname==nil
						dbtname=options['name']
						if version==0x30 or version==0xf5
							dbtname =~ /\.(DBF|FPT)$/i
						else
							dbtname=~/\.(DBF|DBT)$/i
						end
					end
					dbttmp=Memo.new
					memoversion=(version&15)
					memoversion=5 if version==0x30
					dbttmp.create('name'=>dbtname,'version'=>memoversion,'dbf_filename'=>basename) or return
				end
				return self.class.new(options['new'],false)
			end

			def drop
				filename=@filename
				if @memo!=nil
					@memo.drop
					@memo=nil
				end
				return self.class.superclass.instance_method(:drop).bind(self).call
				Base.drop(filename)
			end

			def prepare_select_nf(args)
				fieldnames=self.field_names
				if !args.empty?
					fieldnames=fieldnames[args]
				end
				return self.prepare_select(fieldnames)
			end

		end
end

class Array
   def to_h
     Hash[*enum_with_index.to_a.flatten]
   end

	def merge_into_hash(arr)
		tmp,hash=arr.dup,{}
		self.each{|key|hash[key]=tmp.shift}
		hash
	end
end

class Hash
	def from_pairs_e(keys,values)
	  hash = {}
	  keys.size.times { |i| hash[ keys[i] ] = values[i] }
	  hash
	end
end

table=XBase::XBase.new('ASKS.DBF',:readonly=>true)
#cur=table.prepare_select("KS","NAS")
cur=table.prepare_select_with_index(['ASKS.CDX','KS'])
#cur.find_eq('z')
#while(val=cur.fetch_hashref)
#	puts val['KS']
#end
table.close
puts "OK"