install:
	rvm install "ruby-2.6.3"
	rvm 2.6.3 do bundle install

serve:
	rvm 2.6.3 do bundle exec jekyll serve
