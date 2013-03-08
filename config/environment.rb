# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Likeme::Application.initialize!

#try big int integer todo: use it in dev
#ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT(8) UNSIGNED DEFAULT NULL auto_increment PRIMARY KEY"
#ActiveRecord::ConnectionAdapters::PgAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT(8) UNSIGNED DEFAULT NULL auto_increment PRIMARY KEY"
