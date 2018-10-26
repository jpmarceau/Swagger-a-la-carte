
module Salc
    class SchemaObjectOptions
        attr_accessor :current_heading
        attr_accessor :render
        def initialize(options)
            @current_heading = 1
            @render = {}
            @render["required"] = true
            @render["type"] = true
            @render["format"] = true
        end
    end
    class SchemaObject
        def initialize(data, options, context)
            @context = context
            @data = data
            @options = SchemaObjectOptions.new(options)
            @object = resolve_object()
            @object_name = data.last["sub_path"] # e.g., 'Pet'
        end

        def get_output()
            "#{format_heading()}#{format_description()}#{format_default_value()}#{format_example()}#{format_properties()}"
        end

        def resolve_object(upper_boundary=-1)
            current_location = @context.registers[:site].data["swagger_specifications"]
            @data.each_with_index do |element, index|
                if index < upper_boundary || upper_boundary == -1
                    current_location = current_location[element["sub_path"]]
                end
            end
            current_location
        end

        def format_heading()
            current_heading = @options.current_heading
            heading_element = current_heading > 6 ? "div" : "h#{current_heading}" # TODO replace 6 with constant
            required = @options.render["required"] && is_required?() ? ", required" : ""
            type = ""
            type_format = ""
            if @options.render["type"]
                type = "undefined"
                if @object.has_key?("$ref")
                    type = @object["$ref"].split("/").last # e.g., 'Pet'
                elsif @object.has_key?("type")
                    type = @object["type"] # e.g., 'string'
                end
                if type == "array"
                    item_type = nil
                    if @object.has_key?("items")
                        items = @object["items"]
                        if items.has_key?("$ref")
                            item_type = items["$ref"].split('/').last # e.g., 'Pet'
                        elsif items.has_key?("type")
                            item_type = items["type"]
                        end
                    end
                    type = item_type ? "array of #{item_type}" : type # e.g., 'array of Pet', 'array of string [URL]', 'array'
                end
                type_format = @options.render["format"] && @object.has_key?("format") ? " [#{@object["format"]}]" : "" # e.g., '[int32]', '[dateTime]'
            end
            # e.g., 'photoUrls (array of string [URL]), required'
            heading_string = "<span>#{@object_name}<span> (<span>#{type}<span>#{type_format}</span></span>)</span><span>#{required}</span></span>"
            "<#{heading_element}>#{heading_string}</#{heading_element}>"
        end

        def is_required?()
            parent = resolve_object(@data.length - 1)
            parent.has_key?("required") && parent["required"].include?(@object_name)
        end

        def format_description()
            @object.has_key?("description") ? "<p markdown='1'>#{@object["description"]}</p>" : ""
        end

        def format_default_value()
            @object.has_key?("default") ? "<p>Default value: <code>#{@object["default"]}</code></p>" : ""
        end

        def format_example()
            @object.has_key?("example") ? "<p>Sample value: <code>#{@object["example"]}</code></p>" : ""
        end

        def format_properties()
            output = ""
            if @object.has_key?("properties")
                output += "<div>Properties:</div>"
                @data.push({"sub_path" => "properties", "type" => "object"})
                @object["properties"].each do |key, value|
                    property_data = {"sub_path" => key, "type" => "Schema Object"}
                    @data.push(property_data)
                    pso = SchemaObject.new(@data, @options, @context)
                    output += pso.get_output()
                    @data.pop()
                end
                @data.pop()
            end
            output
        end
    end
end