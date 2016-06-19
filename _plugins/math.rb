module Jekyll
  class MathTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      output = '<script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML" type="text/javascript"></script>'
      output += '<script type="text/x-mathjax-config">MathJax.Hub.Config({tex2jax: {inlineMath: [[\'\\\\(\',\'\\\\)\']]}});</script>'
      output

    end
  end
end

Liquid::Template.register_tag('math', Jekyll::MathTag)
