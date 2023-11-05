require 'active_record'
require 'sqlite3'
require 'easyhooks'

class Article
  include Easyhooks < ActiveRecord::Base

  easyhooks do
    action :action1 do
      trigger :trigger1 do
        puts 'trigger1'
      end
      trigger :trigger2 do
        puts 'trigger2'
      end
    end
    action :action2
  end
end

article = Article.new
article.hello
article.actions[:action1].triggers.first[:trigger].block.call