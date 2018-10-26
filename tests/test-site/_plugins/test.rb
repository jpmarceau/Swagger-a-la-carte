module Jekyll
    class RenderTimeTag < Liquid::Tag
        def initialize(tag_name, input, tokens)
        super
        @input = input
        end

        def render(context)
        data = context.registers[:site].data["swagger_specifications"]["petstore"]
        "#{@input} #{data}"
        end
    end
end

Liquid::Template.register_tag('render_time', Jekyll::RenderTimeTag)