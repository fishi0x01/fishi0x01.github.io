module Jekyll
  class HintBlock < Liquid::Block

    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      output = '<div style="background: url(/content-images/note-bulb.png) no-repeat scroll left center transparent; '
      output += 'color: black; padding: 10px 10px 10px 35px; '
 	  output += 'margin: 15px 0px 15px 0px; background-color: #F2F2F2; '
	  output += 'border:1px solid grey; border-radius: 4px; '
	  output += '-webkit-border-radius: 4px; -moz-border-radius: 4px;}">'
      output += Kramdown::Document.new(super(context)).to_html
      output += '</div>'
      output

    end
  end
end

Liquid::Template.register_tag('hint', Jekyll::HintBlock)
