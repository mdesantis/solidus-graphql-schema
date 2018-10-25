#!/usr/bin/env/ruby

if ARGV.size < 2
  STDERR.puts "Usage: $0 <schema_json_file> <graphql-ruby-git_dir> [output_dir || ./graphql/]"
  exit 1
end

require 'json'
require 'logger'
require 'fileutils'
require 'active_support/core_ext/string/inflections'

$log= Logger.new STDOUT
$log.level = Logger::DEBUG
$log.formatter = proc do |severity, datetime, progname, msg| "#{severity.to_s}: #{msg}\n" end

# Schema contains:
# 1) Names of query, mutation, and subscription entry point types
# 2) Types and directives (of which types include almost everything -- query types, mutation types, input types, and response/payload types)
#
# Therefore, obviously types are by far the largest group.
# In Solidus GraphQL API, we split out 3 sub-types into their own directories: interfaces, input objects, and payloads.
# And even though they are all types, we give them different prefix: Interfaces::X, Inputs::X, and Payloads::X.

# Load schema Hash into $schema
schema_text= File.read ARGV.shift
#schema_text.gsub! /hopify.com/, 'olidus.io'
schema_text.gsub! /hopify(?!\.com)/, 'tore'
schema = JSON.parse schema_text
$schema = schema['data']['__schema']

# Define where is the Git checkout of rmosolgo's graphql-ruby
$graphql_ruby_dir= ARGV.shift

# Define directory where generated files will be output, defaults to ./graphql
$out_dir= ARGV.shift || 'graphql'

# Names of query/mutation/subscription entry points
$query= $mutation= $subscription= nil

# Hash containing a 'catalog' of a bunch of stuff for looking up during execution.
$catalog = {

  # Mapping of types in schema to our types.
  #
  # In general, almost everything in GraphQL is a type. However, as mentioned we
  # sub-divide types into 1) interfaces, 2) inputs, 3) payloads, and 4) all other types.
  # We also set class name to be <type>::<name>, such as Interfaces::Node.
  # Because of that, when the code starts, it needs to do a first pass through all types
  # to figure out what sub-type/full name in Solidus GraphQL they map to.
  # E.g.:
  # 'AppliedDiscount' => 'Interfaces::AppliedDiscount'
  #
  # Also, this list is used to map built-in types to the same value, since they don't need to
  # get any custom prefix.
  # (The list of these built-in types in populated automatically from data found in graphql-ruby.)
  #
  # Also, this list can be used to remap any type to any other/different name in Solidus' GraphQL, if needed.
  names: {
    'ID' => 'ID'
  },

  # List of original names and output files they map to. Both for schema/autogenerated files
  # and for user-modifiable files.
  schema_outputs: {
  },
  outputs: {
  },

  # Contents of output files (schema/autogenerated files, and user-implementable files)
  schema_contents: Hash.new([]),
  contents: Hash.new([]),

  # Dependencies -- used to detect/solve circular dependencies
  # Format is: ClassAString => ClassBString
  # E.g.   Checkout => Customer, Customer => Checkout
  depends: {},

  # List of built-in types.
  # Format: TypeNameString => true
  builtins: {},

  # This lists any problems found during parsing which may affect the
  # success of conversion of JSON schema to .rb files. Currently used/populated
  # but without any practical effect.
  problems: {
    directives: {},
  },
}

# This is the entry point into the program. It invokes all necessary functions,
# writes results to disk and exits.
def run
  $schema.each do |k, v|
    case k
    when 'queryType'
      $query= v['name'] if v
    when 'mutationType'
      $mutation= v['name'] if v
    when 'subscriptionType'
      $subscription= v['name'] if v
    when 'directives'
      parse_directives v
    when 'types'
      parse_types_1 v
    else
      STDERR.puts "Unrecognized schema element '#{k}'. This probably means that the parser file '#{$0}' needs to be updated to support it."
      exit 1
    end
  end

  # Now we are certain that $query/$mutation/$subscription are filled in.
  # They contain the names of types that serve as entry points into the respective parts of schema.
  if !$query; $log.fatal "Did not find name of query entry in JSON schema; exiting."; exit 1 end
  if !$mutation; $log.fatal "Did not find name of mutation entry in JSON schema; exiting."; exit 1 end
  if $subscription
    $log.error "Found a 'subscription' entry point. Previously this wasn't present, so an update to '#{$0}' is needed to support it. For implementation, see existing implementations for queries and mutations; exiting."
    exit 1
  end

  # Let's now parse all types. This is the pass 2 of type parsing.
  parse_types_2 $schema['types']

  # And now we can output all files to disk.
  output_files()

  #pp $catalog

  exit 0
end

#####################################################################
# Helper methods below

def parse_directives(v)
  $log.info "Found %s directives." % [v.size]
  v.each do |d|
    n= d['name']
    if File.exists? "#{$graphql_ruby_dir}/lib/graphql/directive/#{n}_directive.rb"
      $log.debug "Skipping parsing of directive '#{n}' which is a built-in supported by graphql-ruby."
      next
    end
    $log.warn "Directive '#{n}' found in schema, but does not appear supported in graphql-ruby, and graphql-ruby currently also does not support defining custom directives. If this directive will appear used anywhere, then this warning will be promoted to an error; continuing."
    $catalog[:problems][:directives][n] = true
  end
end

# First pass of parsing types
def parse_types_1(v)
  #if $catalog[:builtins].keys.size== 0
  # STDERR.puts 'parse_directives() must be called before parse_types_1(); exiting.'
  # exit 1
  #end

  builtins = Dir["#{$graphql_ruby_dir}/lib/graphql/types/*.rb"]
  builtins.each do |b|
    bc = File.read b
    bc =~ /class\s+(\w+)\s+</
    next unless $1
    $log.debug "Registering type '#{$1}' as built-in type supported by graphql-ruby."
    $catalog[:names][$1] = "::GraphQL::Types::#{$1}"
    $catalog[:builtins][$1] = true
    next
  end

  # Do just some basic things here, which need to be done in 1st pass.
  # The types are parsed "for real" later, in pass 2. This 1st pass is here
  # to solve a chicken-or-egg problem.
  v.each do |t|
    next if check_skip(t)

    name = t['name']

    # Do not overwrite (just skip) built-in types
    next if $catalog[:names][name]

    if $catalog[:names][name]
      $log.fatal "Duplicate type name #{name}. This represents an unhandled case in the script and should be looked into manually; exiting."
      exit 1
    end

    $catalog[:names][name] = sgname(t)
    name = $catalog[:names][t['name']]

    # Even though contents will be filled in later, register files for output to disk here.
    of= name.dup
    of.gsub! '::', '/'
    # This is the schema-related part (should be non-modifiable by user)
    $catalog[:schema_outputs][name]= of.underscore
    # This is the implementation-related part (user should add implementation code)
    $catalog[:outputs][name]= of.underscore
  end
end

def parse_types_2(v)
  $log.info "Found total %s types." % [v.size]

  v.each do |t|
    next if check_skip(t)

    orig_name= t['name']
    new_name = $catalog[:names][orig_name]
    unless orig_name and new_name
      STDERR.puts "parse_types_2() did not find a mapping for #{orig_name}; exiting."
      exit 1
    end

    unless new_name
      STDERR.puts "Encountered type #{orig_name} which doesn't appear seen before. Must be an error in parse_types_1(); exiting."
      exit 1
    end

    helper= {}

    case t['kind']
    when 'ENUM'
      helper['base_type']= 'BaseEnum'
    when 'SCALAR'
      helper['base_type']= 'BaseScalar'
    when 'INPUT_OBJECT'
      helper['base_type']= 'BaseInput'
    else
      helper['base_type']= 'BaseObject'
    end

    $catalog[:schema_contents][new_name]= [template('schema/type_header', t, helper)]
    $catalog[:contents][new_name]= [template('type_header', t, helper)]

    # Main block - parsing of type's fields
    if t['fields']
      t['fields'].each do |f|

        chain = []
        if ft = f['type']
          while ft
            chain.unshift ft
            ft = ft['ofType']
          end
        end
        string = ''
        chain.each do |t2|
          if t2['kind'] == 'NON_NULL' and !t2['name']; string.sub! /true$/, 'false'
          elsif t2['kind'] == 'LIST' and !t2['name']; string = "[#{string}], null: true"
          else
            suffix= ''
            ret_name= t2['name']
            if ret_name.sub! /Connection$/, ''
              suffix = '.connection_type'
            end
            ret_name= $catalog[:names][ret_name]
            unless ret_name
              STDERR.puts "No name map for #{t2['name']}. Check that you are properly looking up entries in $catalog[:names] Hash; exiting."
              exit 1
            end

            $catalog[:depends][new_name] ||= {}
            $catalog[:depends][new_name][ret_name] = true
            if (new_name != ret_name) && ($catalog[:depends][ret_name]) && ($catalog[:depends][ret_name][new_name])
              $log.info "Class #{new_name} depends on #{ret_name} and vice-versa. Will handle accordingly."
              helper['schema_preamble']= "class Spree::GraphQL::Schema::#{ret_name} < Spree::GraphQL::Schema::Types::BaseObject; end\n\n"
              #helper['preamble']= "module Spree::GraphQL::#{ret_name}; end\n\n"
            end

            unless ret_name=~ /^::/
              ret_name= '::Spree::GraphQL::Schema::'+ ret_name
            end

            string = "#{ret_name}, null: true"
          end
        end # chain.each do |t2|

        # graphql-ruby has two specifics:
        # 1) Types have null: true/false
        # 2) Additionally, in lists of type, the 'null: false' is default and not allowed to be specified
        # So the following is needed to comply with that:
        string.gsub! ', null: false]', ']'

        helper['type_name']= string
        if helper['schema_preamble']
          arr= $catalog[:schema_contents][new_name]
          arr.unshift helper['schema_preamble'] unless arr.include? helper['schema_preamble']
          helper['schema_preamble']= nil
        end
        if helper['preamble']
          arr= $catalog[:contents][new_name]
          arr.unshift helper['preamble'] unless arr.include? helper['preamble']
          helper['preamble']= nil
        end
        $catalog[:schema_contents][new_name].push template 'schema/field_header', f, helper
        $catalog[:contents][new_name].push template 'field', f, helper

        if f['args']
          $catalog[:schema_contents][new_name].push ''
          f['args'].each do |f|
            chain = []
            if ft = f['type']
              while ft
                chain.unshift ft
                ft = ft['ofType']
              end
            end
            string= ''
            chain.each do |t|
              if t['kind'] == 'NON_NULL' and !t['name']; string.sub! /false$/, 'true'
              elsif t['kind'] == 'LIST' and !t['name']; string = "[#{string}], required: false"
              else
                arg_type= t['name']
                suffix = ''
                if arg_type.sub! /Connection$/, ''
                  suffix = '.connection_type'
                end
                helper = { 'name' => arg_type.underscore }
                arg_type = $catalog[:names][arg_type]
                unless arg_type=~ /^::/
                  arg_type= '::Spree::GraphQL::Schema::'+ arg_type
                end
                string = "#{arg_type + suffix}, required: false"
              end
            end

            # graphql-ruby has two specifics:
            # 1) Types have null: true/false, while arguments have required: true/false
            # 2) Additionally, in lists of type, the 'null: false' is default and not allowed to be specified
            # So the following is needed to comply with that:
            string.gsub! ', required: true]', ', null: true]'
            string.gsub! ', required: false]', ']'

            helper['type_name']= string
            $catalog[:schema_contents][new_name].push template 'schema/argument', f, helper
          end
        end
        $catalog[:schema_contents][new_name].push template 'schema/field_footer'
      end # t['fields'].each
    end # endif t['fields']
    $catalog[:schema_contents][new_name].push template 'schema/type_footer'
    $catalog[:contents][new_name].push template 'type_footer'
  end
end

def sgname(t)
  name = t['name'].dup

  # If name has already been figured out.
  if $catalog[:names][name]
    return $catalog[:names][name]
  end

  ret= ( if t['kind'] == 'INTERFACE'
    name.sub! /Interface$/, ''
    'Interfaces::'
  elsif t['kind'] == 'INPUT_OBJECT' || t['name'] =~ /Input(?:V\d+)?$/
    name.sub! /Input(V\d+)?$/, '\1'
    'Inputs::'
  elsif t['name'] =~ /Payload(?:V\d+)?$/
    name.sub! /Payload(V\d+)?$/, '\1'
    'Payloads::'
  else
    name.sub! /Connection$/, ''
    'Types::'
  end ) + name
  if !ret
    STDERR.puts "sgname() failed for #{t['name']}; exiting."
    exit 1
  end
  ret
end

def output_files
  # We know how query and mutation type are called, and can already generate schema.rb
  name= 'Schema'
  $catalog[:schema_contents][name] = template('schema', { 'query' => $query, 'mutation' => $mutation})
  $catalog[:schema_outputs][name] = 'schema'

  name= 'Types::BaseObject'
  $catalog[:schema_contents][name]= template('schema/types/base_object')
  $catalog[:schema_outputs][name]= 'types/base_object'
  # User part:
  $catalog[:contents][name]= template('types/base_object')
  $catalog[:outputs][name]= 'types/base_object'

  name= 'Types::BaseEnum'
  $catalog[:schema_contents][name]= template('schema/types/base_enum')
  $catalog[:schema_outputs][name]= 'types/base_enum'
  # User part:
  $catalog[:contents][name]= template('types/base_enum')
  $catalog[:outputs][name]= 'types/base_enum'

  name= 'Types::BaseScalar'
  $catalog[:schema_contents][name]= template('schema/types/base_scalar')
  $catalog[:schema_outputs][name]= 'types/base_scalar'
  # User part:
  $catalog[:contents][name]= template('types/base_scalar')
  $catalog[:outputs][name]= 'types/base_scalar'

  name= 'Types::BaseInput'
  $catalog[:schema_contents][name]= template('schema/types/base_input')
  $catalog[:schema_outputs][name]= 'types/base_input'
  # User part:
  $catalog[:contents][name]= template('types/base_input')
  $catalog[:outputs][name]= 'types/base_input'

  # Output schema parts:
  $catalog[:schema_outputs].each do |name, file|
    content = $catalog[:schema_contents][name]
    content = (Array === content) ? content.flatten.join('') : content
    outfile = "#{$out_dir}/schema/#{file}.rb"
    FileUtils.mkdir_p File.dirname outfile
    File.open(outfile, 'w') { |f| f.write content }
  end

  # Output user parts:
  $catalog[:outputs].each do |name, file|
    content = $catalog[:contents][name]
    content = (Array === content) ? content.flatten.join('') : content
    outfile = "#{$out_dir}/#{file}.rb"
    FileUtils.mkdir_p File.dirname outfile
    File.open(outfile, 'w') { |f| f.write "#{content}\n" }
  end

  # Output total file list:
  outfile = "#{$out_dir}/file_list.rb"
  FileUtils.mkdir_p File.dirname outfile
  File.open(outfile, 'w') { |f| f.write template('file_list.rb') +
    $catalog[:outputs].values.map{|f| %Q{require_relative "./#{f}"}}.join("\n") + "\n\n" +
    $catalog[:schema_outputs].values.map{|f| %Q{require_relative "./schema/#{f}"}}.join("\n")
  }
end

# Beware here that all variable interpolations must pass. E.g., if you have
# `type['name'].underscore` in any part of content, then either all calls to template()
# must have `type['name']` non-nil, or you need to wrap it into (type['name']||'').underscore.
def template(file, type = {}, helper = {})
{
'file_list.rb' => %q{# This file lists all the files that were auto-generated.
# It cannot be used as-is because the order of includes
# does not represent actual dependencies between files.
#
# Use it only for convenience to easily spot additions
# or removals in the list of files and to then update file
# all.rb manually, taking the necessary order of includes
# into account.

require 'graphql'

module Spree
  module GraphQL
    module Schema
      module Inputs
      end
      module Interfaces
      end
      module Payloads
      end
      module Types
      end
    end
    module Inputs
    end
    module Interfaces
    end
    module Payloads
    end
    module Types
    end
  end
end

},
# Schema parts:
'schema' => "class Spree::GraphQL::Schema::Schema < GraphQL::Schema
  query ::Spree::GraphQL::Schema::Types::#{type['query']}
  mutation ::Spree::GraphQL::Schema::Types::#{type['mutation']}
end
",
'schema/type_header' => "class Spree::GraphQL::Schema::#{$catalog[:names][type['name']]} < Spree::GraphQL::Schema::Types::#{helper['base_type'] || 'BaseObject'}
  graphql_name '#{type['name']}'
  include ::Spree::GraphQL::#{$catalog[:names][type['name']]}
",
'schema/field_header' => "
  field :#{(type['name'] || '').underscore}, #{helper['type_name']} do
    description %q{#{type['description']}}
",
'schema/argument' => "    argument :#{(type['name']||'').underscore}, #{helper['type_name']}\n",
'schema/field_footer' => "  end",
'schema/type_footer' => "\nend\n",
'schema/types/base_object' => 'class Spree::GraphQL::Schema::Types::BaseObject < GraphQL::Schema::Object
  global_id_field :id
end
',
'schema/types/base_enum' => 'class Spree::GraphQL::Schema::Types::BaseEnum < GraphQL::Schema::Enum
end
',
'schema/types/base_scalar' => 'class Spree::GraphQL::Schema::Types::BaseScalar < GraphQL::Schema::Scalar
end
',
'schema/types/base_input' => 'class Spree::GraphQL::Schema::Types::BaseInput < GraphQL::Schema::InputObject
end
',
# User parts:
'types/base_object' => 'class Spree::GraphQL::Types::BaseObject
end
',
'types/base_enum' => 'class Spree::GraphQL::Types::BaseEnum
end
',
'types/base_scalar' => 'class Spree::GraphQL::Types::BaseScalar
end
',
'types/base_input' => 'class Spree::GraphQL::Types::BaseInput
end
',
'type_header' => "module Spree::GraphQL::#{$catalog[:names][type['name']]}\n",
'field' => "
  # #{(type['description']||'').gsub /\s*\n+\s*/, ' '}
  # Returns: #{helper['type_name']}
  def #{(type['name'] || '').underscore}() # TODO obj, args, ctx
  end
",
'type_footer' => "\nend\n",
}[file]
end

def check_skip(t)
  # This method is only called for toplevel types. And in them, we are not
  # interested in Connection/Edge types.
  return true if (t['name']=~ /(?:Connection|Edge)$/) || (t['name']=~ /^__/) || ($catalog[:builtins][t['name']])
  false
end

####
run
