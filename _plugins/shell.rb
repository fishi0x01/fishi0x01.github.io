module Jekyll
  class ShellBlock < Liquid::Block

    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      output = '<pre style="background: black; color: green;">'
      output += super
      output += '</pre>'
      output
    end
  end
end

Liquid::Template.register_tag('shell', Jekyll::ShellBlock)
