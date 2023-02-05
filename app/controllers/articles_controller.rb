class ArticlesController < ApplicationController
  def index
    # debugger
    @articles = Article.all
  end

  def index_two
  end
end
