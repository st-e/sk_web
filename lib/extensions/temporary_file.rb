# encoding: utf-8

# Contrary to Ruby's Tempfile, this file will not be deleted automatically;
# the name of the file is returned. Also, it is not thread safe, although
# it does guarantee that no two threads or processes will try to create the
# same file when using this method.
def write_temporary_file(prefix, extension='', tmpdir=Dir::tmpdir)
	max_tries=10

	failure=0
	begin
		# Make a filename which does not yet exist
		n=0
		begin
			t=Time.now.strftime("%Y%m%d")
			filename="#{prefix}-#{t}-#{$$}-#{rand(0x100000000).to_s(36)}-#{n}#{extension}"
			tmpname=File.join(tmpdir, filename)

			lock=tmpname+'.lock'
			n+=1
		end while File.exist?(lock) or File.exist?(tmpname)

		Dir.mkdir(lock)
	rescue => ex
		failure+=1
		retry if failure < max_tries
		raise "Cannot generate tempfile: #{ex}"
	end


	begin
		tmpfile=File.open(tmpname, File::RDWR|File::CREAT|File::EXCL, 0600)
		Dir.rmdir(lock)

		yield(tmpfile)
	ensure
		tmpfile.close
	end

	tmpname
end


