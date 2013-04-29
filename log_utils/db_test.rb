# INSTALL:

# install ruby, devkit, oracle client including sqlplus and sdk components
# SET ORACLE_HOME=<path to client>
# set path=<path to client>;%path%;

# gem install -r ruby-oci8

require 'rubygems'
require 'OCI8'


oci = OCI8.new('GAIA_MANT_PRO','0VHG8fsW','ORC5PRE')
oci.exec('select * from TFG_LINEAS') do |record|
  puts record.join(',')
end