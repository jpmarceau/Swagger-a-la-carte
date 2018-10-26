require 'json'
require_relative 'salc_schema_object'

module Jekyll
    class Swagger_a_la_carte < Liquid::Tag
        def initialize(tag_name, input, tokens)
            super
            @input = input

            # swagger path
            input_path = input.split[0].split('.')
            classifyArr(input_path)
            puts input_path
            @parsed_input = input_path

            # json options
            input_options = JSON.parse(input.split[1])
            @parsed_options = input_options
        end

        def render(context)
            # Ensure the swagger version is supported
            data = context.registers[:site].data["swagger_specifications"]["SearchApi"]
            if data['swagger'] != '2.0'
                "Swagger Version not supported"
            else
                so = Salc::SchemaObject.new(@parsed_input, @parsed_options, context)
                "#{so.get_output()}"
            end
        end

        def classifyArr(arr)
            # create hashes
            arr.collect! { |element|
                element = {'sub_path' => element, 'type' => 'to be determined'}
            }
            # first element is always a SwaggerObjet
            arr[0]['type'] = 'SwaggerObject'
            arr.each_with_index do |element, i|
                if i > 0 
                    element['type'] = sub_path_to_type(arr, i)
                end
            end
        end

        def sub_path_to_type(arr, i)
            if i == 1
                case arr[i]['sub_path']
                # Swagger object
                when 'info'
                    'Info Object'
                when 'host'
                    'string'
                when 'basePath'
                    'string'
                when 'schemes'
                    '[string]'
                when 'consumes'
                    '[string]'
                when 'produces'
                    '[string]'
                when 'paths'
                    'Paths Object'
                when 'definitions'
                    'Definitions Object'
                when 'parameters'
                    'Parameters Definitions Object'
                when 'responses'
                    'Responses Definitions Object'
                when 'securityDefinitions'
                    'Security Definitions Object'
                when 'security'
                    '[Security Requirement Object]'
                when 'tags'
                    '[Tag Object]'
                when 'externalDocs'
                    'External Documentation Object'
                else 
                    'undefined'
                end
            elsif arr[i-1]['type'] == 'Paths Object'
                # Paths object
                if arr[i]['sub_path'][0] == '/'
                    'Path Item Object'
                else
                    'undefined'
                end
            elsif arr[i-1]['type'] == 'Definitions Object'
                # Schema Object
                'Schema Object'
            elsif arr[i-1]['type'] == 'Schema Object'
                # if properties, we are dealing with an array of Schema object
                if arr[i]['sub_path'] == 'properties'
                    '[Schema Object]'
                else
                    'undefined'
                end
            elsif arr[i-1]['type'] == 'Path Item Object'
                case arr[i]['sub_path']
                # Swagger object
                #when '$ref'
                #    'string'
                when 'get'
                    'Operation Object'
                when 'put'
                    'Operation Object'
                when 'post'
                    'Operation Object'
                when 'delete'
                    'Operation Object'
                when 'options'
                    'Operation Object'
                when 'head'
                    'Operation Object'
                when 'patch'
                    'Operation Object'
                when 'parameters'
                   'string'
                else
                    'undefined'
                end
            end
        end
    end
end

Liquid::Template.register_tag('swagger_alc', Jekyll::Swagger_a_la_carte)